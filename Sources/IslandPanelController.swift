import AppKit
import Combine
import SwiftUI

private struct IslandLayoutAnchor {
    let centerX: CGFloat
    let topY: CGFloat
}

@MainActor
final class IslandPanelController {
    private let viewModel = IslandViewModel()
    private let todoStore: TodoStore
    private let musicController: MusicController
    private let panel: IslandPanel
    private let hostingController: NSHostingController<IslandRootView>
    private var cancellables: Set<AnyCancellable> = []
    private var anchor: IslandLayoutAnchor?

    init(todoStore: TodoStore, musicController: MusicController) {
        self.todoStore = todoStore
        self.musicController = musicController

        hostingController = NSHostingController(
            rootView: IslandRootView(
                viewModel: viewModel,
                todoStore: todoStore,
                musicController: musicController
            )
        )
        hostingController.sizingOptions = []

        let initialFrame = CGRect(origin: .zero, size: IslandState.closed.size)
        panel = IslandPanel(
            contentRect: initialFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        configurePanel()
        installContent()
        bindState()
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
        panel.contentViewController = hostingController
    }

    private func installContent() {
        hostingController.view.frame = CGRect(origin: .zero, size: viewModel.state.size)
    }

    private func bindState() {
        viewModel.$state
            .removeDuplicates(by: { $0 == $1 })
            .sink { [weak self] state in
                self?.updateFrame(animated: true)
                self?.syncFocus(for: state)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.refreshAnchor()
                self?.updateFrame(animated: false)
            }
            .store(in: &cancellables)
    }

    private func syncFocus(for state: IslandState) {
        switch state {
        case .open:
            panel.makeKeyAndOrderFront(nil)
        case .closed:
            panel.orderFrontRegardless()
        }
    }

    private func updateFrame(animated: Bool) {
        if anchor == nil {
            refreshAnchor()
        }
        guard let anchor else { return }

        let targetSize = viewModel.state.size
        hostingController.preferredContentSize = targetSize
        hostingController.view.frame = CGRect(origin: .zero, size: targetSize)
        let frame = CGRect(
            x: anchor.centerX - targetSize.width / 2,
            y: anchor.topY - targetSize.height,
            width: targetSize.width,
            height: targetSize.height
        )

        panel.setFrame(frame, display: true, animate: animated)
        logFrame(frame)
    }

    private func refreshAnchor() {
        guard let screen = currentScreen() else { return }

        anchor = IslandLayoutAnchor(
            centerX: islandCenterX(for: screen),
            topY: islandTopY(for: screen)
        )
        logScreen(screen)
    }

    private func currentScreen() -> NSScreen? {
        if let screen = panel.screen {
            return screen
        }

        return NSScreen.main ?? NSScreen.screens.first
    }

    private func islandCenterX(for screen: NSScreen) -> CGFloat {
        let leftArea = screen.auxiliaryTopLeftArea ?? .zero
        let rightArea = screen.auxiliaryTopRightArea ?? .zero

        guard !leftArea.isEmpty, !rightArea.isEmpty else {
            return screen.frame.midX
        }

        return (leftArea.maxX + rightArea.minX) / 2
    }

    private func islandTopY(for screen: NSScreen) -> CGFloat {
        let notchBottomY = notchBottomY(for: screen)
        let overlap: CGFloat = 14
        return notchBottomY + overlap
    }

    private func safeFrame(for screen: NSScreen) -> CGRect {
        let insets = screen.safeAreaInsets
        return CGRect(
            x: screen.frame.minX + insets.left,
            y: screen.frame.minY + insets.bottom,
            width: screen.frame.width - insets.left - insets.right,
            height: screen.frame.height - insets.top - insets.bottom
        )
    }

    private func notchBottomY(for screen: NSScreen) -> CGFloat {
        let leftArea = screen.auxiliaryTopLeftArea ?? .zero
        let rightArea = screen.auxiliaryTopRightArea ?? .zero

        if !leftArea.isEmpty, !rightArea.isEmpty {
            return min(leftArea.minY, rightArea.minY)
        }

        return safeFrame(for: screen).maxY
    }

    private func logScreen(_ screen: NSScreen) {
        let safeFrame = safeFrame(for: screen)
        let leftArea = screen.auxiliaryTopLeftArea ?? .zero
        let rightArea = screen.auxiliaryTopRightArea ?? .zero
        NSLog(
            """
            [ShimmerX] screen frame=\(NSStringFromRect(screen.frame)) visible=\(NSStringFromRect(screen.visibleFrame)) safeInsets=(top:\(screen.safeAreaInsets.top), left:\(screen.safeAreaInsets.left), bottom:\(screen.safeAreaInsets.bottom), right:\(screen.safeAreaInsets.right)) safeFrame=\(NSStringFromRect(safeFrame)) auxLeft=\(NSStringFromRect(leftArea)) auxRight=\(NSStringFromRect(rightArea)) notchBottomY=\(notchBottomY(for: screen)) anchor=(x:\(anchor?.centerX ?? 0), top:\(anchor?.topY ?? 0))
            """
        )
    }

    private func logFrame(_ frame: CGRect) {
        NSLog("[ShimmerX] state=\(viewModel.state) frame=\(NSStringFromRect(frame))")
    }
}
