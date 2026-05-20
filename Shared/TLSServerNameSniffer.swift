import Foundation

/// Best-effort TLS ClientHello SNI extraction for outbound data-plane drops (Chrome HTTPS).
enum TLSServerNameSniffer {
    static func serverName(from data: Data) -> String? {
        let bytes = [UInt8](data)
        guard bytes.count >= 43, bytes[0] == 0x16 else {
            return nil
        }
        var offset = 5
        guard offset < bytes.count, bytes[offset] == 0x01 else {
            return nil
        }
        offset += 4
        guard offset + 2 + 32 < bytes.count else {
            return nil
        }
        offset += 2 + 32
        guard offset < bytes.count else {
            return nil
        }
        let sessionIDLen = Int(bytes[offset])
        offset += 1 + sessionIDLen
        guard offset + 2 <= bytes.count else {
            return nil
        }
        let cipherLen = Int(bytes[offset]) << 8 | Int(bytes[offset + 1])
        offset += 2 + cipherLen
        guard offset < bytes.count else {
            return nil
        }
        let compLen = Int(bytes[offset])
        offset += 1 + compLen
        guard offset + 2 <= bytes.count else {
            return nil
        }
        let extTotal = Int(bytes[offset]) << 8 | Int(bytes[offset + 1])
        offset += 2
        let extEnd = offset + extTotal
        guard extEnd <= bytes.count else {
            return nil
        }
        while offset + 4 <= extEnd {
            let extType = Int(bytes[offset]) << 8 | Int(bytes[offset + 1])
            let extLen = Int(bytes[offset + 2]) << 8 | Int(bytes[offset + 3])
            offset += 4
            guard offset + extLen <= extEnd else {
                return nil
            }
            if extType == 0, extLen >= 5 {
                var nameOffset = offset + 1
                let nameLen = Int(bytes[nameOffset]) << 8 | Int(bytes[nameOffset + 1])
                nameOffset += 2
                guard bytes[offset] == 0,
                      nameLen > 0,
                      nameOffset + nameLen <= offset + extLen else {
                    return nil
                }
                let raw = String(bytes: bytes[nameOffset..<(nameOffset + nameLen)], encoding: .utf8)
                return raw.flatMap { BlocklistEvaluation.canonicalHost(hostname: $0) }
            }
            offset += extLen
        }
        return nil
    }
}
