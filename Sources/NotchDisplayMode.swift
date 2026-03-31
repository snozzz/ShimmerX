import CoreGraphics

enum NotchDisplayMode: Equatable {
    case closed
    case open

    var contentSize: CGSize {
        switch self {
        case .closed:
            return CGSize(width: 236, height: 52)
        case .open:
            return CGSize(width: 468, height: 220)
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .closed:
            return 26
        case .open:
            return 30
        }
    }
}
