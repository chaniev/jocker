import Foundation

struct GameSessionCodec {
    func encode(_ snapshot: GameSessionSnapshot) throws -> Data {
        try snapshot.validate()
        return try JSONEncoder().encode(snapshot)
    }
    func decode(_ data: Data) throws -> GameSessionSnapshot {
        struct Header: Decodable { let schemaVersion: Int }
        guard try JSONDecoder().decode(Header.self, from: data).schemaVersion == 1 else {
            throw GameSessionError.unsupportedVersion
        }
        let snapshot = try JSONDecoder().decode(GameSessionSnapshot.self, from: data)
        try snapshot.validate()
        return snapshot
    }
}
