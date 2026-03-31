import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var islandController: IslandPanelController?
    private let todoStore = TodoStore()
    private let musicController = MusicController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        islandController = IslandPanelController(todoStore: todoStore, musicController: musicController)
        islandController?.show()
    }
}
