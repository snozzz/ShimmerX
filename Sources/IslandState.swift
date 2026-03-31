import CoreGraphics

enum IslandState: CaseIterable {
    case idle
    case compact
    case expanded

    var size: CGSize {
        switch self {
        case .idle:
            return CGSize(width: 132, height: 38)
        case .compact:
            return CGSize(width: 214, height: 46)
        case .expanded:
            return CGSize(width: 430, height: 198)
        }
    }
}
