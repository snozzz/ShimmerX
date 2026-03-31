import AppKit
import CoreGraphics

struct NotchAnchor: Equatable {
    let centerX: CGFloat
    let topY: CGFloat
}

@MainActor
enum NotchGeometry {
    static func activeScreen(for panel: NSPanel?) -> NSScreen? {
        if let screen = panel?.screen {
            return screen
        }

        return NSScreen.main ?? NSScreen.screens.first
    }

    static func anchor(for screen: NSScreen) -> NotchAnchor {
        NotchAnchor(
            centerX: notchCenterX(for: screen),
            topY: notchBottomY(for: screen) + 18
        )
    }

    static func frame(for mode: NotchDisplayMode, anchor: NotchAnchor) -> CGRect {
        let size = mode.contentSize
        return CGRect(
            x: anchor.centerX - size.width / 2,
            y: anchor.topY - size.height,
            width: size.width,
            height: size.height
        )
    }

    static func safeFrame(for screen: NSScreen) -> CGRect {
        let insets = screen.safeAreaInsets
        return CGRect(
            x: screen.frame.minX + insets.left,
            y: screen.frame.minY + insets.bottom,
            width: screen.frame.width - insets.left - insets.right,
            height: screen.frame.height - insets.top - insets.bottom
        )
    }

    static func notchBottomY(for screen: NSScreen) -> CGFloat {
        let leftArea = screen.auxiliaryTopLeftArea ?? .zero
        let rightArea = screen.auxiliaryTopRightArea ?? .zero

        if !leftArea.isEmpty, !rightArea.isEmpty {
            return min(leftArea.minY, rightArea.minY)
        }

        return safeFrame(for: screen).maxY
    }

    static func notchCenterX(for screen: NSScreen) -> CGFloat {
        let leftArea = screen.auxiliaryTopLeftArea ?? .zero
        let rightArea = screen.auxiliaryTopRightArea ?? .zero

        if !leftArea.isEmpty, !rightArea.isEmpty {
            return (leftArea.maxX + rightArea.minX) / 2
        }

        return screen.frame.midX
    }
}
