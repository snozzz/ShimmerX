import Combine
import Foundation

@MainActor
final class IslandViewModel: ObservableObject {
    @Published private(set) var state: IslandState = .closed
    @Published private(set) var title: String = "Now Playing"
    @Published private(set) var subtitle: String = "Hover to expand"
    @Published private(set) var isShowingQuickCapturePreview = false

    private var closeTask: Task<Void, Never>?
    private var isPointerHovering = false

    func handlePrimaryAction() {
        switch state {
        case .open:
            close()
        case .closed:
            open()
        }
    }

    func hoverChanged(_ isHovering: Bool) {
        isPointerHovering = isHovering

        if isHovering {
            cancelCloseTask()
            open()
        } else {
            scheduleClose()
        }
    }

    func presentQuickCapturePreview() {
        guard state != .open else { return }
        transition(
            to: .closed,
            title: "Quick Capture",
            subtitle: "Todo shortcut ready",
            isQuickCapturePreview: true
        )
        scheduleClose(after: .milliseconds(2200))
    }

    func open() {
        cancelCloseTask()
        transition(to: .open, title: "ShimmerX", subtitle: "Media and quick actions")
    }

    func close() {
        cancelCloseTask()
        transition(to: .closed, title: "Now Playing", subtitle: "Hover to expand")
    }

    private func scheduleClose(after delay: Duration = .milliseconds(450)) {
        closeTask?.cancel()
        closeTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self, self.state == .open, !self.isPointerHovering else { return }
                self.close()
            }
        }
    }

    private func cancelCloseTask() {
        closeTask?.cancel()
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
