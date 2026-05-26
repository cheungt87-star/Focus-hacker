import SwiftUI

struct FocusSessionPresetPicker: View {
    @ObservedObject var viewModel: AppShellViewModel
    let isEnabled: Bool
    let onCustomSession: () -> Void

    private let gridColumns = [
        GridItem(.flexible(), spacing: DesignSpacing.spacing2),
        GridItem(.flexible(), spacing: DesignSpacing.spacing2)
    ]

    var body: some View {
        VStack(alignment: .center, spacing: DesignSpacing.spacing3) {
            Text("Select your focus session")
                .font(.macDSLabel)
                .foregroundStyle(MacDS.Color.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)

            LazyVGrid(columns: gridColumns, spacing: DesignSpacing.spacing2) {
                FocusSessionPresetButton(
                    preset: FocusSessionPresets.classic,
                    isSelected: viewModel.selectedFocusPresetID == FocusSessionPresets.classic.id,
                    isEnabled: isEnabled
                ) {
                    viewModel.applyFocusPreset(FocusSessionPresets.classic)
                }

                FocusSessionPresetButton(
                    preset: FocusSessionPresets.intense,
                    isSelected: viewModel.selectedFocusPresetID == FocusSessionPresets.intense.id,
                    isEnabled: isEnabled
                ) {
                    viewModel.applyFocusPreset(FocusSessionPresets.intense)
                }

                FocusSessionPresetButton(
                    preset: FocusSessionPresets.expert,
                    isSelected: viewModel.selectedFocusPresetID == FocusSessionPresets.expert.id,
                    isEnabled: isEnabled
                ) {
                    viewModel.applyFocusPreset(FocusSessionPresets.expert)
                }

                FocusSessionCustomButton(
                    isEnabled: isEnabled,
                    action: onCustomSession
                )
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct FocusSessionPresetButton: View {
    let preset: FocusSessionPreset
    let isSelected: Bool
    let isEnabled: Bool
    let action: () -> Void

    private var strokeColor: Color {
        if isSelected {
            return MacDS.Color.accentTeal
        }
        if preset.isRecommended {
            return MacDS.Color.accentTeal.opacity(0.55)
        }
        return MacDS.Color.border
    }

    private var fillColor: Color {
        isSelected ? MacDS.Color.accentTealLightest : MacDS.Color.cardBackground
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: DesignSpacing.spacing1) {
                    Text(preset.name)
                        .font(.macDSLabel.weight(.semibold))
                        .foregroundStyle(MacDS.Color.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Spacer(minLength: 0)

                    if preset.isRecommended {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 8, weight: .semibold))
                            Text("Recommended")
                                .font(.macDSCaption.weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundStyle(MacDS.Color.accentTeal)
                    }

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(MacDS.Color.accentTeal)
                    }
                }

                Text(preset.descriptionLine)
                    .font(.macDSHelper)
                    .foregroundStyle(MacDS.Color.textSecondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Total: \(preset.totalSessionMinutes) min")
                    .font(.macDSCaption)
                    .foregroundStyle(MacDS.Color.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .padding(.horizontal, DesignSpacing.spacing2)
            .padding(.vertical, DesignSpacing.spacing2)
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                    .fill(fillColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                    .stroke(strokeColor, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var accessibilityLabel: String {
        var parts = [preset.name, preset.descriptionLine, "Total \(preset.totalSessionMinutes) minutes"]
        if preset.isRecommended {
            parts.append("Recommended")
        }
        if isSelected {
            parts.append("Selected")
        }
        return parts.joined(separator: ", ")
    }
}

private struct FocusSessionCustomButton: View {
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: DesignSpacing.spacing1) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Custom session")
                        .font(.macDSLabel.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .foregroundStyle(MacDS.Color.textSecondary)

                Text("Opens full timer config")
                    .font(.macDSCaption)
                    .foregroundStyle(MacDS.Color.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .padding(.horizontal, DesignSpacing.spacing2)
            .padding(.vertical, DesignSpacing.spacing2)
            .background(
                RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                    .fill(MacDS.Color.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                    .stroke(MacDS.Color.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .accessibilityLabel("Custom session, opens full timer configuration")
    }
}
