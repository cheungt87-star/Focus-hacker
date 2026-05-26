import SwiftUI

struct SidebarColorThemeToggle: View {
    @Binding var selection: AppearancePreference

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing2) {
            Text("Color theme")
                .font(.macDSLabel)
                .foregroundStyle(MacDS.Color.textSecondary)

            themeSegmentedControl
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Color theme")
    }

    private var themeSegmentedControl: some View {
        HStack(spacing: 2) {
            ForEach(AppearancePreference.allCases) { preference in
                themeSegment(preference: preference)
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                .fill(MacDS.Color.surfaceDisabled)
        )
    }

    private func themeSegment(preference: AppearancePreference) -> some View {
        let isSelected = selection == preference
        return Button {
            guard selection != preference else { return }
            selection = preference
        } label: {
            Text(preference.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? MacDS.Color.textPrimary : MacDS.Color.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.vertical, DesignSpacing.spacing2)
                .padding(.horizontal, DesignSpacing.spacing2)
                .frame(maxWidth: .infinity)
                .background(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: MacDS.Radius.standard - 2)
                                .fill(MacDS.Color.accentTealLightest)
                                .overlay(
                                    RoundedRectangle(cornerRadius: MacDS.Radius.standard - 2)
                                        .stroke(MacDS.Color.accentTeal, lineWidth: 1)
                                )
                        }
                    }
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(preference.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
