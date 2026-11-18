import Foundation

/// Lifetime is the app, so recovery and all three variants share writers.
final class GamePersistenceRepository {
    static let shared = GamePersistenceRepository()
    let statistics: FileGameStatisticsStore
    let sessions: FileGameSessionStore

    private init() {
        var root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Jocker", isDirectory: true)
        var failSessionWrites = false
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-uiTestMode"), let index = arguments.firstIndex(of: "-sessionTestID"),
           arguments.indices.contains(index + 1), let id = UUID(uuidString: arguments[index + 1]) {
            root = root.appendingPathComponent("UITests", isDirectory: true).appendingPathComponent(id.uuidString, isDirectory: true)
            failSessionWrites = arguments.contains("-failSessionWrites")
        }
        #endif
        self.statistics = FileGameStatisticsStore(url: root.appendingPathComponent("statistics.json"))
        let shouldFailWrites = failSessionWrites
        self.sessions = FileGameSessionStore(root: root.appendingPathComponent("sessions", isDirectory: true), statistics: self.statistics) { data, url in
            if shouldFailWrites { throw CocoaError(.fileWriteOutOfSpace) }
            try data.write(to: url, options: .atomic)
        }
    }
}
