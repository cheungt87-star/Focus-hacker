import SwiftUI

@available(macOS 14.0, *)
struct ProfileWeeklyProgressCard: View {
    @ObservedObject var viewModel: AppShellViewModel

    var body: some View {
        MacDSCard {
            VStack(alignment: .leading, spacing: DesignSpacing.spacing6) {
                Text("Weekly progress")
                    .font(.macDSCardTitle)
                    .foregroundStyle(MacDS.Color.textPrimary)

                HStack(alignment: .top, spacing: DesignSpacing.spacing6) {
                    goalColumn(
                        title: "Hacker goal",
                        currentMinutes: viewModel.hackerWeeklyCurrentMinutes,
                        targetMinutes: viewModel.hackerWeeklyTargetMinutes,
                        fraction: viewModel.hackerWeeklyProgressFraction,
                        percentDisplay: viewModel.hackerWeeklyMinutesPercentDisplay,
                        accent: MacDS.Color.accentTeal,
                        panelBackground: MacDS.Color.accentTealLightest,
                        panelBorder: MacDS.Color.accentTeal.opacity(0.35)
                    )

                    goalColumn(
                        title: "Personal goal",
                        currentMinutes: viewModel.personalWeeklyCurrentMinutes,
                        targetMinutes: viewModel.personalWeeklyTargetMinutes,
                        fraction: viewModel.personalWeeklyProgressFraction,
                        percentDisplay: viewModel.personalWeeklyMinutesPercentDisplay,
                        accent: MacDS.Color.accentOrange,
                        panelBackground: MacDS.Color.accentOrange.opacity(0.14),
                        panelBorder: MacDS.Color.accentOrange.opacity(0.35)
                    )
                }
            }
        }
        .redacted(reason: viewModel.profileIsLoading ? .placeholder : [])
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Weekly progress")
    }

    private func goalColumn(
        title: String,
        currentMinutes: Int,
        targetMinutes: Int,
        fraction: Double,
        percentDisplay: Int,
        accent: Color,
        panelBackground: Color,
        panelBorder: Color
    ) -> some View {
        VStack(spacing: DesignSpacing.spacing3) {
            Text(title)
                .font(.macDSLabel.weight(.semibold))
                .foregroundStyle(accent)

            MacDSCircularProgressRing(
                fraction: fraction,
                percentDisplay: percentDisplay,
                tint: accent,
                centerColor: accent
            )

            VStack(spacing: DesignSpacing.spacing2) {
                Text("\(currentMinutes) / \(targetMinutes) min")
                    .font(.macDSCaption.weight(.semibold))
                    .foregroundStyle(MacDS.Color.textPrimary)
                    .monospacedDigit()

                Text("\(targetMinutes) min / week")
                    .macDSHelperText()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSpacing.spacing4)
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: MacDS.Radius.standard))
        .overlay(
            RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                .stroke(panelBorder, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(title), \(percentDisplay) percent complete, \(currentMinutes) of \(targetMinutes) minutes, target \(targetMinutes) minutes per week."
        )
    }
}
