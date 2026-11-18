import Foundation

protocol GameSessionStore: AnyObject {
    func load(_ slot: GameSessionSlot, completion: @escaping (Result<GameSessionSnapshot?, Error>) -> Void)
    func save(_ snapshot: GameSessionSnapshot, completion: @escaping (Result<Void, Error>) -> Void)
    func discard(_ slot: GameSessionSlot, completion: @escaping (Result<Void, Error>) -> Void)
    func markTerminal(_ snapshot: GameSessionSnapshot, completion: @escaping (Result<Void, Error>) -> Void)
    func recover(completion: @escaping (Result<Void, Error>) -> Void)
}
