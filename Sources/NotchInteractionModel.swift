import Foundation

@MainActor
final class NotchInteractionModel: ObservableObject {
    @Published private(set) var mode: NotchDisplayMode = .closed
    @Published private(set) var title: String = "Now Playing"
    @Published private(set) var subtitle: String = "Hover to expand"
    @Published private(set) var isQuickCapturePreview = false

    private var closeTask: Task<Void, Never>?
    private var previewResetTask: Task<Void, Never>?
    private var isPointerInside = false
    private var isEngaged = false

    func pointerChanged(_ isInside: Bool) {
        isPointerInside = isInside

        if isInside {
            open()
        } else {
            scheduleClose()
        }
    }

    func setEngaged(_ engaged: Bool) {
        isEngaged = engaged

        if engaged {
            open()
        } else if !isPointerInside {
            scheduleClose()
        }
    }

    func toggle() {
        switch mode {
        case .closed:
            open()
        case .open:
            if isEngaged {
                return
            }
            closeNow()
        }
    }

    func presentQuickCapturePreview() {
        cancelPreviewReset()
        cancelClose()
        mode = .closed
        title = "Quick Capture"
        subtitle = "Todo saved"
        isQuickCapturePreview = true

        previewResetTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(1300))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.resetClosedCopy()
            }
        }
    }

    func open() {
        cancelClose()
        mode = .open
        title = "ShimmerX"
        subtitle = "Media and quick actions"
        isQuickCapturePreview = false
    }

    func closeNow() {
        cancelClose()
        resetClosedCopy()
    }

    private func scheduleClose(after delay: Duration = .milliseconds(420)) {
        cancelClose()
        closeTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self, !self.isPointerInside, !self.isEngaged else { return }
                self.resetClosedCopy()
            }
        }
    }

    private func resetClosedCopy() {
        mode = .closed
        title = "Now Playing"
        subtitle = "Hover to expand"
        isQuickCapturePreview = false
    }

    private func cancelClose() {
        closeTask?.cancel()
    }

    private func cancelPreviewReset() {
        previewResetTask?.cancel()
    }
}
