import CoreGraphics

enum IslandState: CaseIterable {
    case closed
    case open

    var size: CGSize {
        switch self {
        case .closed:
            return CGSize(width: 214, height: 46)
        case .open:
            return CGSize(width: 430, height: 198)
        }
    }
}
