import AppKit
import Combine
import SwiftUI

@MainActor
final class IslandPanelController {
    private let viewModel = IslandViewModel()
    private let todoStore: TodoStore
    private let musicController: MusicController
    private let panel: IslandPanel
    private let hostingController: NSHostingController<IslandRootView>
    private var cancellables: Set<AnyCancellable> = []

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

        let initialFrame = CGRect(origin: .zero, size: IslandState.compact.size)
        panel = IslandPanel(
            contentRect: initialFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        configurePanel()
        installContent()
        bindState()
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
        panel.setContentSize(viewModel.state.size)
    }

    private func bindState() {
        viewModel.$state
            .removeDuplicates(by: { $0 == $1 })
            .sink { [weak self] state in
                self?.updateFrame(animated: true)
                self?.syncFocus(for: state)
            }
            .store(in: &cancellables)
    }

    private func syncFocus(for state: IslandState) {
        switch state {
        case .expanded:
            panel.makeKeyAndOrderFront(nil)
        case .idle, .compact:
            panel.orderFrontRegardless()
        }
    }

    private func updateFrame(animated: Bool) {
        guard let screen = currentScreen() else { return }

        let targetSize = viewModel.state.size
        panel.setContentSize(targetSize)

        let origin = CGPoint(
            x: islandCenterX(for: screen) - targetSize.width / 2,
            y: islandTopY(for: screen, islandHeight: targetSize.height)
        )
        let frame = CGRect(origin: origin, size: targetSize)

        if animated {
            panel.animator().setFrame(frame, display: true)
        } else {
            panel.setFrame(frame, display: true)
        }
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

    private func islandTopY(for screen: NSScreen, islandHeight: CGFloat) -> CGFloat {
        let safeFrame = safeFrame(for: screen)
        let gap: CGFloat = 6
        return safeFrame.maxY - gap - islandHeight
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
}
