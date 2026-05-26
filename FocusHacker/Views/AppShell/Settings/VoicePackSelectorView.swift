import SwiftUI

struct VoicePackSelectorView: View {
    @ObservedObject var viewModel: AppShellViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing3) {
            Text(
                "The voice will guide you through your focus sessions, telling you when you need to focus and when to take a break."
            )
            .macDSHelperText()
            .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: DesignSpacing.spacing2) {
                ForEach(VoicePackCardOption.listOptions) { option in
                    VoicePackRow(
                        option: option,
                        isSelected: option.isSelected(
                            soundPack: viewModel.selectedSoundPack,
                            voiceOption: viewModel.selectedVoiceOption,
                            isMuted: viewModel.isAudioMuted
                        ),
                        onPreview: { preview(option) },
                        onSelect: { select(option) }
                    )
                }

                Divider()
                    .overlay(MacDS.Color.dividerLight)

                VoicePackRow(
                    option: .noVoice,
                    isSelected: VoicePackCardOption.noVoice.isSelected(
                        soundPack: viewModel.selectedSoundPack,
                        voiceOption: viewModel.selectedVoiceOption,
                        isMuted: viewModel.isAudioMuted
                    ),
                    onPreview: {},
                    onSelect: { select(.noVoice) }
                )
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Voice options")
        }
    }

    private func select(_ option: VoicePackCardOption) {
        switch option {
        case .voice(let voice):
            viewModel.selectedSoundPack = .voicePrompts
            viewModel.selectedVoiceOption = voice
            viewModel.isAudioMuted = false
        case .noVoice:
            viewModel.isAudioMuted = true
        }
    }

    private func preview(_ option: VoicePackCardOption) {
        guard case .voice(let voice) = option else {
            return
        }
        viewModel.previewVoiceOption(voice)
    }
}
