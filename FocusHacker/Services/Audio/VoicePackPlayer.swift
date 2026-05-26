import AVFoundation
import Foundation

enum VoicePackPhrase: String, Sendable {
    case letsFocus = "lets_focus"
    case takeABreak = "take_a_break"
    case sessionComplete = "session_complete"
}

final class VoicePackPlayer {
    private var player: AVAudioPlayer?

    func play(phrase: VoicePackPhrase, voiceOption: VoiceOption, isMuted: Bool) {
        guard !isMuted else {
            return
        }

        guard let url = url(for: phrase, voiceOption: voiceOption) else {
            return
        }

        do {
            player?.stop()
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.prepareToPlay()
            player = audioPlayer
            audioPlayer.play()
        } catch {
            player = nil
        }
    }

    private func url(for phrase: VoicePackPhrase, voiceOption: VoiceOption) -> URL? {
        let subdirectory = "Voice packs/\(voiceOption.displayName)"
        let candidates = filenameCandidates(for: phrase)

        for filename in candidates {
            if let url = Bundle.main.url(
                forResource: filename,
                withExtension: "mp3",
                subdirectory: subdirectory
            ) {
                return url
            }
        }

        return nil
    }

    private func filenameCandidates(for phrase: VoicePackPhrase) -> [String] {
        switch phrase {
        case .sessionComplete:
            return [phrase.rawValue, "Session_complete"]
        case .letsFocus, .takeABreak:
            return [phrase.rawValue]
        }
    }
}
