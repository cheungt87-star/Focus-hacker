import Foundation

/// Selectable voice rows shown in Choose your voice settings.
enum VoicePackCardOption: Identifiable, Equatable, Sendable {
    case voice(VoiceOption)
    case noVoice

    static let listOptions: [VoicePackCardOption] =
        VoiceOption.allCases.map { .voice($0) }

    enum SelectionStyle: Sendable {
        case teal
        case neutral
    }

    var id: String {
        switch self {
        case .voice(let option):
            return "voice-\(option.rawValue)"
        case .noVoice:
            return "no-voice"
        }
    }

    var title: String {
        switch self {
        case .voice(let option):
            return option.displayName
        case .noVoice:
            return "No voice"
        }
    }

    var selectionStyle: SelectionStyle {
        switch self {
        case .voice:
            return .teal
        case .noVoice:
            return .neutral
        }
    }

    var showsSelectedBadge: Bool {
        switch self {
        case .voice:
            return true
        case .noVoice:
            return false
        }
    }

    var showsPreviewControl: Bool {
        switch self {
        case .voice:
            return true
        case .noVoice:
            return false
        }
    }

    var voiceOption: VoiceOption? {
        if case .voice(let option) = self {
            return option
        }
        return nil
    }

    func isSelected(soundPack: AudioSoundPack, voiceOption: VoiceOption, isMuted: Bool) -> Bool {
        switch self {
        case .voice(let option):
            return soundPack == .voicePrompts && voiceOption == option && !isMuted
        case .noVoice:
            return isMuted
        }
    }
}
