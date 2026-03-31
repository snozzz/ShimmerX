import AppKit
import Combine
import SwiftUI

@MainActor
final class IslandPanelController {
    private let viewModel = IslandViewModel()
    private let todoStore: TodoStore
    private let musicController: MusicController
    private let panel: IslandPanel
    private var cancellables: Set<AnyCancellable> = []

    init(todoStore: TodoStore, musicController: MusicController) {
        self.todoStore = todoStore
        self.musicController = musicController
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
    }

    private func installContent() {
        let rootView = IslandRootView(
            viewModel: viewModel,
            todoStore: todoStore,
            musicController: musicController
        )
            .frame(
                width: viewModel.state.size.width,
                height: viewModel.state.size.height
            )

        panel.contentView = NSHostingView(rootView: rootView)
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
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }

        let targetSize = viewModel.state.size
        let origin = CGPoint(
            x: screen.frame.midX - targetSize.width / 2,
            y: screen.frame.maxY - topInset(for: screen) - targetSize.height
        )
        let frame = CGRect(origin: origin, size: targetSize)

        if animated {
            panel.animator().setFrame(frame, display: true)
        } else {
            panel.setFrame(frame, display: true)
        }
    }

    private func topInset(for screen: NSScreen) -> CGFloat {
        let visibleHeight = screen.visibleFrame.height
        let fullHeight = screen.frame.height
        let menuBarHeight = fullHeight - visibleHeight
        return max(menuBarHeight + 8, 24)
    }
}
