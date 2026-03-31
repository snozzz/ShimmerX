import Combine
import Foundation

@MainActor
final class IslandViewModel: ObservableObject {
    @Published private(set) var state: IslandState = .compact

    func toggleExpanded() {
        state = state == .expanded ? .compact : .expanded
    }
}
