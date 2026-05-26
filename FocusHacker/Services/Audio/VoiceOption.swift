import Foundation

enum VoiceOption: String, CaseIterable, Identifiable, Sendable {
    case crystal = "Crystal"
    case david = "David"
    case jamal = "Jamal"
    case jocko = "Jocko"
    case kristen = "Kristen"

    var id: String { rawValue }

    var displayName: String { rawValue }

    static let defaultSelection: VoiceOption = .jamal

    static func resolve(storedIdentifier: String?) -> VoiceOption {
        guard let storedIdentifier, !storedIdentifier.isEmpty else {
            return defaultSelection
        }
        return VoiceOption(rawValue: storedIdentifier) ?? defaultSelection
    }
}
