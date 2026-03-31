import AppKit
import Combine
import SwiftUI

@MainActor
final class NotchWindowController {
    private let interactionModel = NotchInteractionModel()
    private let panel: NotchPanel
    private let hostingController: NSHostingController<NotchView>
    private var cancellables: Set<AnyCancellable> = []
    private var anchor: NotchAnchor?

    init(todoStore: TodoStore, musicController: MusicController) {
        hostingController = NSHostingController(
            rootView: NotchView(
                interactionModel: interactionModel,
                todoStore: todoStore,
                musicController: musicController
            )
        )
        hostingController.sizingOptions = []

        panel = NotchPanel(
            contentRect: CGRect(origin: .zero, size: NotchDisplayMode.closed.contentSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        configurePanel()
        bind()
        refreshAnchor()
        updateFrame(animated: false)
    }

    func show() {
        panel.orderFrontRegardless()
    }

    private func configurePanel() {
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.ignoresMouseEvents = false
        panel.isMovable = false
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.isReleasedWhenClosed = false
        panel.contentViewController = hostingController
        hostingController.view.frame = CGRect(origin: .zero, size: NotchDisplayMode.closed.contentSize)
    }

    private func bind() {
        interactionModel.$mode
            .removeDuplicates()
            .sink { [weak self] mode in
                self?.syncFocus(for: mode)
                self?.updateFrame(animated: true)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.refreshAnchor()
                self?.updateFrame(animated: false)
            }
            .store(in: &cancellables)
    }

    private func syncFocus(for mode: NotchDisplayMode) {
        switch mode {
        case .closed:
            panel.orderFrontRegardless()
        case .open:
            panel.makeKeyAndOrderFront(nil)
        }
    }

    private func refreshAnchor() {
        guard let screen = NotchGeometry.activeScreen(for: panel) else { return }
        anchor = NotchGeometry.anchor(for: screen)
        logScreen(screen)
    }

    private func updateFrame(animated: Bool) {
        if anchor == nil {
            refreshAnchor()
        }
        guard let anchor else { return }

        let targetSize = interactionModel.mode.contentSize
        hostingController.preferredContentSize = targetSize
        hostingController.view.frame = CGRect(origin: .zero, size: targetSize)
        panel.setContentSize(targetSize)

        let frame = NotchGeometry.frame(for: interactionModel.mode, anchor: anchor)
        panel.setFrame(frame, display: true, animate: animated)
        logFrame(frame)
    }

    private func logScreen(_ screen: NSScreen) {
        let leftArea = screen.auxiliaryTopLeftArea ?? .zero
        let rightArea = screen.auxiliaryTopRightArea ?? .zero
        let safeFrame = NotchGeometry.safeFrame(for: screen)
        let anchor = NotchGeometry.anchor(for: screen)
        NSLog(
            """
            [ShimmerX] screen frame=\(NSStringFromRect(screen.frame)) visible=\(NSStringFromRect(screen.visibleFrame)) safeInsets=(top:\(screen.safeAreaInsets.top), left:\(screen.safeAreaInsets.left), bottom:\(screen.safeAreaInsets.bottom), right:\(screen.safeAreaInsets.right)) safeFrame=\(NSStringFromRect(safeFrame)) auxLeft=\(NSStringFromRect(leftArea)) auxRight=\(NSStringFromRect(rightArea)) notchBottomY=\(NotchGeometry.notchBottomY(for: screen)) anchor=(x:\(anchor.centerX), top:\(anchor.topY))
            """
        )
    }

    private func logFrame(_ frame: CGRect) {
        NSLog("[ShimmerX] mode=\(interactionModel.mode) frame=\(NSStringFromRect(frame))")
    }
}
