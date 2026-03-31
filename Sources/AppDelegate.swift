import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var islandController: IslandPanelController?
    private let todoStore = TodoStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        islandController = IslandPanelController(todoStore: todoStore)
        islandController?.show()
    }
}
