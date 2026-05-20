import AVFoundation
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
    func playTransitionCue(for event: TimerTransitionEvent, soundPack: AudioSoundPack, isMuted: Bool)
    func preview(soundPack: AudioSoundPack, isMuted: Bool)
}

final class AudioCueService: NSObject, AudioCuePlaying {
    private let synthesizer = AVSpeechSynthesizer()

    func playTransitionCue(for event: TimerTransitionEvent, soundPack: AudioSoundPack, isMuted: Bool) {
        guard !isMuted else {
            return
        }

        let phrase = phrase(for: event, soundPack: soundPack)
        guard let phrase else {
            return
        }
        speak(text: phrase, soundPack: soundPack)
    }

    func preview(soundPack: AudioSoundPack, isMuted: Bool) {
        guard !isMuted else {
            return
        }
        let text: String
        switch soundPack {
        case .voicePrompts:
            text = "Voice prompts preview."
        case .chimes:
            text = "Ding."
        }
        speak(text: text, soundPack: soundPack)
    }
}

private extension AudioCueService {
    func phrase(for event: TimerTransitionEvent, soundPack: AudioSoundPack) -> String? {
        switch event {
        case .focusStarted:
            return soundPack == .voicePrompts ? "Get back to work." : "Ding ding."
        case .shortRestStarted, .longRestStarted:
            return soundPack == .voicePrompts ? "Time to rest." : "Dong."
        case .sessionCompleted:
            return soundPack == .voicePrompts ? "Great session. You did it." : "Ta da!"
        case .sessionEndedEarly:
            return nil
        }
    }

    func speak(text: String, soundPack: AudioSoundPack) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = soundPack == .voicePrompts ? 0.47 : 0.56
        utterance.pitchMultiplier = soundPack == .voicePrompts ? 1.0 : 1.25
        utterance.volume = 1.0
        synthesizer.speak(utterance)
    }
}
