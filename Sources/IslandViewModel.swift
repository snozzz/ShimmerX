import Combine
import Foundation

@MainActor
final class IslandViewModel: ObservableObject {
    @Published private(set) var state: IslandState = .idle
    @Published private(set) var title: String = "ShimmerX"
    @Published private(set) var subtitle: String = "Hover to wake"
    @Published private(set) var isShowingQuickCapturePreview = false

    private var autoCollapseTask: Task<Void, Never>?
    private var idleTask: Task<Void, Never>?

    func handlePrimaryAction() {
        switch state {
        case .expanded:
            collapseToCompact()
        case .idle, .compact:
            expand()
        }
    }

    func hoverChanged(_ isHovering: Bool) {
        guard state != .expanded else { return }

        if isHovering {
            cancelIdleTask()
            transition(to: .compact, title: "Now Playing", subtitle: "Tap to expand")
        } else {
            scheduleIdleTransition()
        }
    }

    func presentQuickCapturePreview() {
        guard state != .expanded else { return }
        transition(
            to: .compact,
            title: "Quick Capture",
            subtitle: "Todo shortcut ready",
            isQuickCapturePreview: true
        )
        scheduleIdleTransition(after: .milliseconds(2200))
    }

    private func expand() {
        cancelIdleTask()
        transition(to: .expanded, title: "ShimmerX Preview", subtitle: "Media and quick actions")
        scheduleAutoCollapse()
    }

    private func collapseToCompact() {
        autoCollapseTask?.cancel()
        transition(to: .compact, title: "Now Playing", subtitle: "Tap to expand")
        scheduleIdleTransition()
    }

    private func scheduleAutoCollapse() {
        autoCollapseTask?.cancel()
        autoCollapseTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(6))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.collapseToCompact()
            }
        }
    }

    private func scheduleIdleTransition(after delay: Duration = .seconds(1.6)) {
        idleTask?.cancel()
        idleTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.transition(to: .idle, title: "ShimmerX", subtitle: "Hover to wake")
            }
        }
    }

    private func cancelIdleTask() {
        idleTask?.cancel()
    }

    private func transition(to newState: IslandState, title: String, subtitle: String) {
        transition(to: newState, title: title, subtitle: subtitle, isQuickCapturePreview: false)
    }

    private func transition(
        to newState: IslandState,
        title: String,
        subtitle: String,
        isQuickCapturePreview: Bool
    ) {
        state = newState
        self.title = title
        self.subtitle = subtitle
        self.isShowingQuickCapturePreview = isQuickCapturePreview
    }
}
