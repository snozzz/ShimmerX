import AppKit
import Foundation

enum MusicPlaybackState: String {
    case playing
    case paused
    case stopped
    case unavailable

    var actionSymbol: String {
        switch self {
        case .playing:
            return "pause.fill"
        case .paused, .stopped, .unavailable:
            return "play.fill"
        }
    }

    var label: String {
        switch self {
        case .playing:
            return "Playing"
        case .paused:
            return "Paused"
        case .stopped:
            return "Stopped"
        case .unavailable:
            return "Music"
        }
    }
}

struct MusicSnapshot: Equatable {
    var title: String
    var artist: String
    var album: String
    var state: MusicPlaybackState

    static let unavailable = MusicSnapshot(
        title: "Apple Music",
        artist: "Open Music to enable playback controls",
        album: "",
        state: .unavailable
    )

    var subtitle: String {
        if !artist.isEmpty { return artist }
        if !album.isEmpty { return album }
        return state.label
    }
}

@MainActor
final class MusicController: ObservableObject {
    @Published private(set) var snapshot: MusicSnapshot = .unavailable

    private var pollTimer: Timer?
    private let separator = "|||"

    init() {
        refresh()
        startPolling()
    }

    func refresh() {
        snapshot = fetchSnapshot()
    }

    func playPause() {
        run(script: """
        tell application "Music"
            activate
            playpause
        end tell
        """)
        refresh()
    }

    func nextTrack() {
        run(script: """
        tell application "Music"
            activate
            next track
        end tell
        """)
        refresh()
    }

    func previousTrack() {
        run(script: """
        tell application "Music"
            activate
            previous track
        end tell
        """)
        refresh()
    }

    private func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    private func fetchSnapshot() -> MusicSnapshot {
        let source = """
        tell application "Music"
            if not running then
                return "__UNAVAILABLE__"
            end if

            set trackTitle to ""
            set trackArtist to ""
            set trackAlbum to ""

            try
                set trackTitle to name of current track
            end try

            try
                set trackArtist to artist of current track
            end try

            try
                set trackAlbum to album of current track
            end try

            return (player state as text) & "\(separator)" & trackTitle & "\(separator)" & trackArtist & "\(separator)" & trackAlbum
        end tell
        """

        guard let output = run(script: source), output != "__UNAVAILABLE__" else {
            return .unavailable
        }

        let components = output.components(separatedBy: separator)
        guard let rawState = components.first else {
            return .unavailable
        }

        return MusicSnapshot(
            title: value(at: 1, in: components, fallback: "Apple Music"),
            artist: value(at: 2, in: components, fallback: rawState.capitalized),
            album: value(at: 3, in: components, fallback: ""),
            state: MusicPlaybackState(rawValue: rawState) ?? .unavailable
        )
    }

    private func value(at index: Int, in components: [String], fallback: String) -> String {
        guard components.indices.contains(index) else { return fallback }
        let value = components[index].trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? fallback : value
    }

    @discardableResult
    private func run(script source: String) -> String? {
        var error: NSDictionary?
        let appleScript = NSAppleScript(source: source)
        let descriptor = appleScript?.executeAndReturnError(&error)

        if let error {
            NSLog("Music AppleScript error: \(error)")
        }

        return descriptor?.stringValue
    }
}
