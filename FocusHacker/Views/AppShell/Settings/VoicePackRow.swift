import SwiftUI

struct VoicePackRow: View {
    let option: VoicePackCardOption
    let isSelected: Bool
    let onPreview: () -> Void
    let onSelect: () -> Void

    private var selectionStyle: SettingsSelectionStyle {
        switch option.selectionStyle {
        case .teal:
            return .teal
        case .neutral:
            return .neutral
        }
    }

    var body: some View {
        SettingsSelectionRow(
            title: option.title,
            isSelected: isSelected,
            showsSelectedBadge: option.showsSelectedBadge,
            style: selectionStyle,
            onSelect: onSelect
        ) {
            if option.showsPreviewControl {
                Button(action: onPreview) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(MacDS.Color.textPrimary)
                        .frame(width: 32, height: 32)
                        .background(MacDS.Color.cardBackground)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(MacDS.Color.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Preview \(option.title)")
                .accessibilityHint("Plays a short sample")
            }
        }
    }
}
