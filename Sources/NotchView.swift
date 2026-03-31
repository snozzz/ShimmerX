import SwiftUI

struct NotchView: View {
    @ObservedObject var interactionModel: NotchInteractionModel
    @ObservedObject var todoStore: TodoStore
    @ObservedObject var musicController: MusicController

    @State private var todoDraft = ""
    @FocusState private var isComposerFocused: Bool

    var body: some View {
        ZStack {
            shell
            if interactionModel.mode == .closed {
                closedContent
            } else {
                openContent
            }
        }
        .frame(
            width: interactionModel.mode.contentSize.width,
            height: interactionModel.mode.contentSize.height
        )
        .contentShape(
            RoundedRectangle(
                cornerRadius: interactionModel.mode.cornerRadius,
                style: .continuous
            )
        )
        .onHover { hovering in
            interactionModel.pointerChanged(hovering)
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.84), value: interactionModel.mode)
        .onChange(of: isComposerFocused) { _, focused in
            interactionModel.setEngaged(focused)
        }
    }

    private var shell: some View {
        RoundedRectangle(cornerRadius: interactionModel.mode.cornerRadius, style: .continuous)
            .fill(.black.opacity(0.94))
            .overlay {
                RoundedRectangle(cornerRadius: interactionModel.mode.cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.34), radius: 26, y: 10)
    }

    private var closedContent: some View {
        HStack(spacing: 12) {
            capsuleArtwork

            VStack(alignment: .leading, spacing: 2) {
                Text(closedTitle)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))

                Text(closedSubtitle)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Image(systemName: "waveform")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.72))
        }
        .padding(.horizontal, 14)
        .contentShape(Rectangle())
        .onTapGesture(perform: interactionModel.toggle)
    }

    private var openContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                albumArtwork

                VStack(alignment: .leading, spacing: 4) {
                    Text(openTitle)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(openSubtitle)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.58))
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                Button(action: interactionModel.toggle) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.72))
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                mediaChip(systemImage: "backward.fill", title: "Prev", action: musicController.previousTrack)
                mediaChip(
                    systemImage: musicController.snapshot.state.actionSymbol,
                    title: musicController.snapshot.state == .playing ? "Pause" : "Play",
                    action: musicController.playPause
                )
                mediaChip(systemImage: "forward.fill", title: "Next", action: musicController.nextTrack)
                mediaChip(systemImage: "checklist", title: "Todo") {
                    isComposerFocused = true
                }
            }

            HStack(alignment: .top, spacing: 8) {
                mediaSummaryCard
                todoCard
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var capsuleArtwork: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(red: 0.21, green: 0.65, blue: 0.98), Color(red: 0.11, green: 0.26, blue: 0.92)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 30, height: 30)
            .overlay {
                Image(systemName: "music.note")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
    }

    private var albumArtwork: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(red: 0.95, green: 0.46, blue: 0.29), Color(red: 0.85, green: 0.17, blue: 0.32)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 56, height: 56)
            .overlay {
                Image(systemName: musicController.snapshot.state.actionSymbol)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
    }

    private func mediaChip(systemImage: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white.opacity(0.92))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(.white.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }

    private var mediaSummaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: musicController.snapshot.state == .playing ? "waveform" : "music.note")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))

                Text(musicController.snapshot.state.label)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer(minLength: 0)
            }

            Text(musicController.snapshot.title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)

            Text(musicController.snapshot.subtitle)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(0.06))
        )
    }

    private var todoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Note")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            HStack(spacing: 8) {
                TextField("Add a todo", text: $todoDraft)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.white.opacity(0.08))
                    )
                    .focused($isComposerFocused)
                    .onSubmit(addTodo)

                Button("Save", action: addTodo)
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.85))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(.white.opacity(todoDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.2 : 0.92))
                    )
            }

            if todoStore.recentItems.isEmpty {
                Text("Recent todos appear here.")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            } else {
                ForEach(todoStore.recentItems) { item in
                    Button {
                        todoStore.toggle(item)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(item.isCompleted ? .green.opacity(0.95) : .white.opacity(0.65))

                            Text(item.title)
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(item.isCompleted ? 0.45 : 0.88))
                                .strikethrough(item.isCompleted, color: .white.opacity(0.35))

                            Spacer(minLength: 0)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(0.06))
        )
    }

    private func addTodo() {
        let trimmed = todoDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        todoStore.add(title: trimmed)
        todoDraft = ""
        isComposerFocused = false
        interactionModel.presentQuickCapturePreview()
    }

    private var closedTitle: String {
        if interactionModel.isQuickCapturePreview {
            return interactionModel.title
        }

        return musicController.snapshot.state == .unavailable ? interactionModel.title : musicController.snapshot.state.label
    }

    private var closedSubtitle: String {
        if interactionModel.isQuickCapturePreview {
            return interactionModel.subtitle
        }

        return musicController.snapshot.state == .unavailable ? interactionModel.subtitle : musicController.snapshot.title
    }

    private var openTitle: String {
        musicController.snapshot.title
    }

    private var openSubtitle: String {
        musicController.snapshot.subtitle
    }
}
