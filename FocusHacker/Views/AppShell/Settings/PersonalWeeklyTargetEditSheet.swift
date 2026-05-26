import SwiftUI

struct PersonalWeeklyTargetEditSheet: View {
    @Binding var hours: Int
    @Binding var minutes: Int
    let onCancel: () -> Void
    let onSave: () -> Void

    private var totalMinutes: Int {
        PersonalWeeklyTargetFormatting.clampedTotalMinutes(hours: hours, minutes: minutes)
    }

    private var deltaVersusHackerGoal: Int {
        PersonalWeeklyTargetFormatting.deltaVersusHackerGoalMinutes(personalMinutes: totalMinutes)
    }

    private var percentVersusHackerGoal: Int {
        PersonalWeeklyTargetFormatting.percentVersusHackerGoal(personalMinutes: totalMinutes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing4) {
            Text("Personal target")
                .font(.macDSCardTitle)
                .foregroundStyle(MacDS.Color.textPrimary)

            Text("Heads up — changing your target resets your streak.")
                .macDSHelperText()
                .fixedSize(horizontal: false, vertical: true)

            PersonalWeeklyTargetStepperRow(
                label: "Hours",
                value: hours,
                suffix: "h",
                canDecrement: PersonalWeeklyTargetFormatting.canDecrementHours(hours: hours, minutes: minutes),
                canIncrement: PersonalWeeklyTargetFormatting.canIncrementHours(hours: hours, minutes: minutes),
                onDecrement: {
                    PersonalWeeklyTargetFormatting.decrementHours(hours: &hours, minutes: &minutes)
                },
                onIncrement: {
                    PersonalWeeklyTargetFormatting.incrementHours(hours: &hours, minutes: &minutes)
                }
            )

            PersonalWeeklyTargetStepperRow(
                label: "Minutes",
                value: minutes,
                suffix: "m",
                canDecrement: PersonalWeeklyTargetFormatting.canDecrementMinutes(hours: hours, minutes: minutes),
                canIncrement: PersonalWeeklyTargetFormatting.canIncrementMinutes(hours: hours, minutes: minutes),
                onDecrement: {
                    PersonalWeeklyTargetFormatting.decrementMinutes(hours: &hours, minutes: &minutes)
                },
                onIncrement: {
                    PersonalWeeklyTargetFormatting.incrementMinutes(hours: &hours, minutes: &minutes)
                }
            )

            totalDisplay

            hackerGoalComparison

            HStack(spacing: DesignSpacing.spacing3) {
                Spacer()
                Button("Cancel", action: onCancel)
                    .buttonStyle(MacDSSecondaryButtonStyle())
                    .keyboardShortcut(.cancelAction)
                Button("Save", action: onSave)
                    .buttonStyle(MacDSPrimaryButtonStyle())
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(DesignSpacing.spacing5)
        .frame(width: 360)
        .background(MacDS.Color.backgroundPrimary)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Edit personal target")
    }

    private var totalDisplay: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing2) {
            Text("Total")
                .font(.macDSLabel)
                .foregroundStyle(MacDS.Color.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: DesignSpacing.spacing1) {
                Text("\(totalMinutes)")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(MacDS.Color.textPrimary)
                    .monospacedDigit()
                Text("min / wk")
                    .font(.macDSHelper)
                    .foregroundStyle(MacDS.Color.textSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(totalMinutes) minutes per week")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSpacing.spacing3)
        .background(MacDS.Color.inputBackground)
        .clipShape(RoundedRectangle(cornerRadius: MacDS.Radius.standard))
        .overlay(
            RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                .stroke(MacDS.Color.border, lineWidth: 1)
        )
    }

    private var hackerGoalComparison: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing2) {
            Text("vs hacker goal")
                .font(.macDSCaption)
                .foregroundStyle(MacDS.Color.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: DesignSpacing.spacing3) {
                Text(PersonalWeeklyTargetFormatting.deltaVersusHackerGoalDisplay(deltaMinutes: deltaVersusHackerGoal))
                    .font(.macDSBody.monospacedDigit())
                    .foregroundStyle(comparisonDeltaColor)

                Spacer(minLength: DesignSpacing.spacing2)

                Text(PersonalWeeklyTargetFormatting.percentVersusHackerGoalDisplay(percent: percentVersusHackerGoal))
                    .font(.macDSBody.monospacedDigit())
                    .foregroundStyle(comparisonPercentColor)
                    .multilineTextAlignment(.trailing)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSpacing.spacing3)
        .background(MacDS.Color.inputBackground)
        .clipShape(RoundedRectangle(cornerRadius: MacDS.Radius.standard))
        .overlay(
            RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                .stroke(MacDS.Color.border, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            PersonalWeeklyTargetFormatting.hackerGoalComparisonAccessibilityLabel(
                deltaMinutes: deltaVersusHackerGoal,
                percent: percentVersusHackerGoal
            )
        )
    }

    private var comparisonDeltaColor: Color {
        if deltaVersusHackerGoal > 0 {
            return MacDS.Color.accentTeal
        }
        if deltaVersusHackerGoal < 0 {
            return MacDS.Color.textTertiary
        }
        return MacDS.Color.textSecondary
    }

    private var comparisonPercentColor: Color {
        comparisonDeltaColor
    }
}

private struct PersonalWeeklyTargetStepperRow: View {
    let label: String
    let value: Int
    let suffix: String
    let canDecrement: Bool
    let canIncrement: Bool
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    var body: some View {
        HStack(spacing: DesignSpacing.spacing3) {
            Text(label)
                .font(.macDSLabel)
                .foregroundStyle(MacDS.Color.textPrimary)
                .frame(width: 64, alignment: .leading)

            HStack(spacing: DesignSpacing.spacing2) {
                stepperButton(systemName: "minus", isEnabled: canDecrement, action: onDecrement)
                    .accessibilityLabel("Decrease \(label)")

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(value)")
                        .font(.macDSBody.monospacedDigit())
                        .foregroundStyle(MacDS.Color.textPrimary)
                        .frame(minWidth: 28, alignment: .trailing)
                    Text(suffix)
                        .font(.macDSCaption)
                        .foregroundStyle(MacDS.Color.textSecondary)
                }
                .frame(minWidth: 56)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(value) \(suffix)")

                stepperButton(systemName: "plus", isEnabled: canIncrement, action: onIncrement)
                    .accessibilityLabel("Increase \(label)")
            }

            Spacer(minLength: 0)
        }
    }

    private func stepperButton(systemName: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(MacDS.Color.textPrimary)
                .frame(width: 28, height: 28)
                .background(MacDS.Color.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: MacDS.Radius.standard))
                .overlay(
                    RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                        .stroke(MacDS.Color.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.35)
    }
}

#if DEBUG
#Preview {
    struct PreviewHost: View {
        @State private var hours = 13
        @State private var minutes = 20

        var body: some View {
            PersonalWeeklyTargetEditSheet(
                hours: $hours,
                minutes: $minutes,
                onCancel: {},
                onSave: {}
            )
        }
    }
    return PreviewHost()
}
#endif
