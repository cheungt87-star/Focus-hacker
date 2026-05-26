import AppKit
import Foundation

enum AudioSoundPack: String, CaseIterable, Identifiable, Sendable {
    case voicePrompts = "voice-prompts"
    case chimes = "chimes"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .voicePrompts:
            return "Voice Prompts"
        case .chimes:
            return "Chimes"
        }
    }

    static func from(storedIdentifier: String) -> AudioSoundPack {
        AudioSoundPack(rawValue: storedIdentifier) ?? .voicePrompts
    }
}

protocol AudioCuePlaying: AnyObject {
    var voiceOption: VoiceOption { get set }
    func playTransitionCue(for event: TimerTransitionEvent, soundPack: AudioSoundPack, isMuted: Bool)
    /// Subtle per-second chime during Get Ready; no spoken voice (voice plays on `.focusStarted`).
    func playGetReadyTickCue(isMuted: Bool)
    func preview(soundPack: AudioSoundPack, isMuted: Bool)
    /// Settings preview — ignores mute.
    func previewVoiceOption(_ voiceOption: VoiceOption)
    func previewChimesSoundPack()
}

final class AudioCueService: AudioCuePlaying {
    var voiceOption: VoiceOption
    private let voicePackPlayer: VoicePackPlayer

    init(voiceOption: VoiceOption = .defaultSelection, voicePackPlayer: VoicePackPlayer = VoicePackPlayer()) {
        self.voiceOption = voiceOption
        self.voicePackPlayer = voicePackPlayer
    }

    func playTransitionCue(for event: TimerTransitionEvent, soundPack: AudioSoundPack, isMuted: Bool) {
        guard !isMuted else {
            return
        }

        switch soundPack {
        case .voicePrompts:
            guard let phrase = voicePhrase(for: event) else {
                return
            }
            voicePackPlayer.play(phrase: phrase, voiceOption: voiceOption, isMuted: isMuted)
        case .chimes:
            guard let soundName = chimeSoundName(for: event) else {
                return
            }
            playSystemSound(named: soundName)
        }
    }

    func playGetReadyTickCue(isMuted: Bool) {
        guard !isMuted else {
            return
        }
        playSystemSound(named: "Tink")
    }

    func preview(soundPack: AudioSoundPack, isMuted: Bool) {
        guard !isMuted else {
            return
        }

        switch soundPack {
        case .voicePrompts:
            voicePackPlayer.play(phrase: .letsFocus, voiceOption: voiceOption, isMuted: isMuted)
        case .chimes:
            playSystemSound(named: "Tink")
        }
    }

    func previewVoiceOption(_ voiceOption: VoiceOption) {
        voicePackPlayer.play(phrase: .letsFocus, voiceOption: voiceOption, isMuted: false)
    }

    func previewChimesSoundPack() {
        playSystemSound(named: "Tink")
    }
}

private extension AudioCueService {
    func voicePhrase(for event: TimerTransitionEvent) -> VoicePackPhrase? {
        switch event {
        case .focusStarted:
            return .letsFocus
        case .shortRestStarted, .longRestStarted:
            return .takeABreak
        case .sessionCompleted:
            return .sessionComplete
        case .sessionEndedEarly:
            return nil
        }
    }

    func chimeSoundName(for event: TimerTransitionEvent) -> String? {
        switch event {
        case .focusStarted:
            return "Tink"
        case .shortRestStarted, .longRestStarted:
            return "Pop"
        case .sessionCompleted:
            return "Glass"
        case .sessionEndedEarly:
            return nil
        }
    }

    func playSystemSound(named name: String) {
        NSSound(named: NSSound.Name(name))?.play()
    }
}
