import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var islandController: IslandPanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        islandController = IslandPanelController()
        islandController?.show()
    }
}
