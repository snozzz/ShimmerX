import Foundation

struct BoringWorkerNotification {
    let name: Notification.Name
}

final class TheBoringWorkerNotifier {
    let showClipboardNotification = BoringWorkerNotification(name: .init("ShimmerX.ShowClipboard"))
    let toggleHudReplacementNotification = BoringWorkerNotification(name: .init("ShimmerX.ToggleHudReplacement"))
    let micStatusNotification = BoringWorkerNotification(name: .init("ShimmerX.MicStatus"))
    let sneakPeakNotification = BoringWorkerNotification(name: .init("ShimmerX.SneakPeak"))
    let toggleMicNotification = BoringWorkerNotification(name: .init("ShimmerX.ToggleMic"))

    func postNotification(name: Notification.Name, userInfo: [AnyHashable: Any]?) {
        NotificationCenter.default.post(name: name, object: nil, userInfo: userInfo)
    }

    func setupObserver(_ observer: Any, notification: BoringWorkerNotification, handler: Selector) {
        NotificationCenter.default.addObserver(
            observer,
            selector: handler,
            name: notification.name,
            object: nil
        )
    }
}
