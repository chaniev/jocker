import Foundation

final class GameSessionPersistenceCoordinator {
    let store: GameSessionStore
    private(set) var persistedRevision: Int?
    private(set) var liveRevision: Int
    let matchID: UUID

    init(store: GameSessionStore, restored: GameSessionSnapshot? = nil) {
        self.store = store
        self.matchID = restored?.matchID ?? UUID()
        self.liveRevision = restored?.revision ?? 0
        self.persistedRevision = restored?.revision
    }
    func nextRevision() -> Int {
        self.liveRevision += 1
        return self.liveRevision
    }
    func save(_ snapshot: GameSessionSnapshot, completion: ((Result<Void, Error>) -> Void)? = nil) {
        self.store.save(snapshot) { [weak self] result in
            if case .success = result, let self {
                self.persistedRevision = max(self.persistedRevision ?? 0, snapshot.revision)
            }
            completion?(result)
        }
    }
}
