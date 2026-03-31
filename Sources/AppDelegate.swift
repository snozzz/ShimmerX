import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var notchController: NotchWindowController?
    private let todoStore = TodoStore()
    private let musicController = MusicController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        notchController = NotchWindowController(todoStore: todoStore, musicController: musicController)
        notchController?.show()
    }
}
