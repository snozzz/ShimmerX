import SwiftUI

struct IslandRootView: View {
    @ObservedObject var viewModel: IslandViewModel
    @State private var isHovering = false

    var body: some View {
        Button(action: viewModel.handlePrimaryAction) {
            content
        }
        .buttonStyle(.plain)
        .frame(
            width: viewModel.state.size.width,
            height: viewModel.state.size.height
        )
        .background {
            Capsule(style: .continuous)
                .fill(.black.opacity(0.92))
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.28), radius: 24, y: 10)
        }
        .scaleEffect(isHovering && viewModel.state != .expanded ? 1.015 : 1)
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

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            idleContent
        case .compact:
            compactContent
        case .expanded:
            expandedContent
        }
    }

    private var idleContent: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.95), .white.opacity(0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 9, height: 9)
                .shadow(color: .white.opacity(0.35), radius: 6)

            Text(viewModel.title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))
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
                Text(viewModel.title)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))

                Text(viewModel.subtitle)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
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
                    Text(viewModel.title)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(viewModel.subtitle)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.58))
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                actionChip(systemImage: "backward.fill", title: "Prev")
                actionChip(systemImage: "pause.fill", title: "Pause")
                actionChip(systemImage: "forward.fill", title: "Next")
                actionChip(systemImage: "checklist", title: "Todo")
            }

            HStack(spacing: 8) {
                featureCard(
                    title: "Media",
                    subtitle: "Playback controls plug in here",
                    systemImage: "waveform"
                )
                featureCard(
                    title: "Quick Note",
                    subtitle: "Global shortcut will open inline capture",
                    systemImage: "text.badge.plus"
                )
            }
        }
        .padding(16)
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
}
