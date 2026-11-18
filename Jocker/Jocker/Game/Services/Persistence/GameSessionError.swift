import Foundation

enum GameSessionError: Error {
    case invalidSnapshot, unsupportedVersion, staleRevision, retiredMatch, occupiedSlot
}
