@testable import FocusHacker
import XCTest

final class VoicePackSelectorTests: XCTestCase {
    func testListIncludesAllVoices() {
        XCTAssertEqual(VoicePackCardOption.listOptions.count, 5)
        for voice in VoiceOption.allCases {
            XCTAssertTrue(VoicePackCardOption.listOptions.contains(.voice(voice)))
        }
    }

    func testDefaultVoiceIsJamal() {
        XCTAssertEqual(VoiceOption.defaultSelection, .jamal)
    }

    func testSelectionStateForVoiceRespectsMute() {
        XCTAssertTrue(
            VoicePackCardOption.voice(.crystal).isSelected(
                soundPack: .voicePrompts,
                voiceOption: .crystal,
                isMuted: false
            )
        )
        XCTAssertFalse(
            VoicePackCardOption.voice(.david).isSelected(
                soundPack: .voicePrompts,
                voiceOption: .crystal,
                isMuted: false
            )
        )
        XCTAssertFalse(
            VoicePackCardOption.voice(.crystal).isSelected(
                soundPack: .voicePrompts,
                voiceOption: .crystal,
                isMuted: true
            )
        )
    }

    func testNoVoiceSelectedWhenMuted() {
        XCTAssertTrue(
            VoicePackCardOption.noVoice.isSelected(
                soundPack: .voicePrompts,
                voiceOption: .crystal,
                isMuted: true
            )
        )
        XCTAssertFalse(
            VoicePackCardOption.noVoice.isSelected(
                soundPack: .voicePrompts,
                voiceOption: .crystal,
                isMuted: false
            )
        )
    }

    func testPreviewVoiceOptionPlaysWithoutChangingStoredVoice() throws {
        let store = UserDefaultsSettingsStore(
            userDefaults: UserDefaults(suiteName: "VoicePackSelectorTests.\(UUID().uuidString)")!,
            appGroupSuiteName: nil
        )
        store.selectedVoiceOption = "David"
        let audio = AudioCueService(voiceOption: .david)
        audio.previewVoiceOption(.crystal)
        XCTAssertEqual(audio.voiceOption, .david)
    }

    func testPreviewChimesDoesNotRequireMuteOff() {
        let audio = AudioCueService(voiceOption: .crystal)
        audio.previewChimesSoundPack()
    }
}
