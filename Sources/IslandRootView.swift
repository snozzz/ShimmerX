import SwiftUI

struct IslandRootView: View {
    @ObservedObject var viewModel: IslandViewModel
    @ObservedObject var todoStore: TodoStore
    @ObservedObject var musicController: MusicController
    @State private var isHovering = false
    @State private var todoDraft = ""
    @FocusState private var isComposerFocused: Bool

    var body: some View {
        ZStack {
            backgroundShape
            content
        }
        .frame(width: viewModel.state.size.width, height: viewModel.state.size.height)
        .contentShape(RoundedRectangle(cornerRadius: viewModel.state == .open ? 28 : viewModel.state.size.height / 2, style: .continuous))
        .scaleEffect(isHovering && viewModel.state != .open ? 1.015 : 1)
        .onHover { hovering in
            isHovering = hovering
            viewModel.hoverChanged(hovering)
        }
        .contextMenu {
            Button("Preview Quick Capture") {
                viewModel.presentQuickCapturePreview()
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.82), value: viewModel.state)
        .animation(.spring(response: 0.28, dampingFraction: 0.88), value: isHovering)
    }

    private var backgroundShape: some View {
        RoundedRectangle(cornerRadius: viewModel.state == .open ? 28 : viewModel.state.size.height / 2, style: .continuous)
            .fill(.black.opacity(0.92))
            .overlay {
                RoundedRectangle(cornerRadius: viewModel.state == .open ? 28 : viewModel.state.size.height / 2, style: .continuous)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.28), radius: 24, y: 10)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .closed:
            compactContent
                .contentShape(Rectangle())
                .onTapGesture(perform: viewModel.handlePrimaryAction)
        case .open:
            expandedContent
        }
    }

    private var compactContent: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.21, green: 0.65, blue: 0.98), Color(red: 0.11, green: 0.26, blue: 0.92)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 28, height: 28)
                .overlay {
                    Image(systemName: "music.note")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(compactTitle)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))

                Text(compactSubtitle)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.72))
        }
        .padding(.horizontal, 14)
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.95, green: 0.46, blue: 0.29), Color(red: 0.85, green: 0.17, blue: 0.32)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: "play.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(expandedTitle)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(expandedSubtitle)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.58))
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                Button(action: viewModel.handlePrimaryAction) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.76))
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(.white.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                Button(action: musicController.previousTrack) {
                    actionChip(systemImage: "backward.fill", title: "Prev")
                }
                .buttonStyle(.plain)

                Button(action: musicController.playPause) {
                    actionChip(systemImage: musicController.snapshot.state.actionSymbol, title: musicController.snapshot.state == .playing ? "Pause" : "Play")
                }
                .buttonStyle(.plain)

                Button(action: musicController.nextTrack) {
                    actionChip(systemImage: "forward.fill", title: "Next")
                }
                .buttonStyle(.plain)

                Button {
                    isComposerFocused = true
                } label: {
                    actionChip(systemImage: "checklist", title: "Todo")
                }
                .buttonStyle(.plain)
            }

            HStack(alignment: .top, spacing: 8) {
                mediaCard
                todoComposer
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func actionChip(systemImage: String, title: String) -> some View {
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

    private func featureCard(title: String, subtitle: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))

            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(0.06))
        )
    }

    private var mediaCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: musicController.snapshot.state == .playing ? "waveform" : "music.note")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))

                Text(musicController.snapshot.state.label)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer(minLength: 0)

                Button("Refresh", action: musicController.refresh)
                    .buttonStyle(.plain)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Text(musicController.snapshot.title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)

            Text(musicController.snapshot.subtitle)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
                .lineLimit(2)

            if !musicController.snapshot.album.isEmpty, musicController.snapshot.album != musicController.snapshot.subtitle {
                Text(musicController.snapshot.album)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.38))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(0.06))
        )
    }

    private var todoComposer: some View {
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
                Text("Recent todos will appear here.")
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
        viewModel.presentQuickCapturePreview()
    }

    private var compactTitle: String {
        if viewModel.isShowingQuickCapturePreview {
            return viewModel.title
        }

        return musicController.snapshot.state == .unavailable ? viewModel.title : musicController.snapshot.state.label
    }

    private var compactSubtitle: String {
        if viewModel.isShowingQuickCapturePreview {
            return viewModel.subtitle
        }

        return musicController.snapshot.state == .unavailable ? viewModel.subtitle : musicController.snapshot.title
    }

    private var expandedTitle: String {
        if viewModel.isShowingQuickCapturePreview {
            return viewModel.title
        }

        return musicController.snapshot.title
    }

    private var expandedSubtitle: String {
        if viewModel.isShowingQuickCapturePreview {
            return viewModel.subtitle
        }

        return musicController.snapshot.subtitle
    }
}
