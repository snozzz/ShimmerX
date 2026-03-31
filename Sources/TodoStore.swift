import Combine
import Foundation

@MainActor
final class TodoStore: ObservableObject {
    @Published private(set) var items: [TodoItem] = []

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        load()
    }

    func add(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        items.insert(TodoItem(title: trimmed), at: 0)
        persist()
    }

    func toggle(_ item: TodoItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isCompleted.toggle()
        persist()
    }

    var recentItems: [TodoItem] {
        Array(items.prefix(4))
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL) else { return }
        items = (try? decoder.decode([TodoItem].self, from: data)) ?? []
    }

    private func persist() {
        do {
            try FileManager.default.createDirectory(
                at: storageURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try encoder.encode(items)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            NSLog("Failed to persist todo items: \(error.localizedDescription)")
        }
    }

    private var storageURL: URL {
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())

        return appSupportURL
            .appendingPathComponent("ShimmerX", isDirectory: true)
            .appendingPathComponent("todos.json")
    }
}
