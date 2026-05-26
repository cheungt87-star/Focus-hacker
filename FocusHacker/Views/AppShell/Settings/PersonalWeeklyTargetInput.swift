import SwiftUI

struct PersonalWeeklyTargetInput: View {
    @Binding var hours: Int
    @Binding var minutes: Int
    var showsRowTitle: Bool = true
    var showsTotalMinutesHelper: Bool = true

    @Environment(\.appUISurface) private var appUISurface

    private var palette: FormChromePalette {
        FormChromePalette.resolve(
            surface: appUISurface,
            timerChrome: TimerChromeTheme(sessionState: .idle, colorScheme: .light)
        )
    }

    private var totalMinutes: Int {
        PersonalWeeklyTargetFormatting.clampedTotalMinutes(hours: hours, minutes: minutes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing2) {
            HStack(alignment: .center, spacing: DesignSpacing.spacing2) {
                if showsRowTitle {
                    Text("Personal target")
                        .font(.macDSLabel)
                        .foregroundStyle(MacDS.Color.textPrimary)
                }

                Spacer(minLength: DesignSpacing.spacing3)

                HStack(alignment: .center, spacing: DesignSpacing.spacing1) {
                    PersonalWeeklyTargetIntField(
                        value: $hours,
                        range: 0...33,
                        suffix: "h",
                        accessibilityLabel: "Hours"
                    )
                    PersonalWeeklyTargetIntField(
                        value: $minutes,
                        range: 0...59,
                        suffix: "m",
                        accessibilityLabel: "Minutes"
                    )
                }
            }

            if showsTotalMinutesHelper {
                Text("\(totalMinutes) min / week")
                    .macDSHelperText()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            PersonalWeeklyTargetFormatting.accessibilityLabel(
                hours: hours,
                minutes: minutes,
                totalMinutes: totalMinutes
            )
        )
    }
}

private struct PersonalWeeklyTargetIntField: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let suffix: String
    let accessibilityLabel: String

    @FocusState private var isFocused: Bool
    @Environment(\.appUISurface) private var appUISurface

    private var palette: FormChromePalette {
        FormChromePalette.resolve(
            surface: appUISurface,
            timerChrome: TimerChromeTheme(sessionState: .idle, colorScheme: .light)
        )
    }

    var body: some View {
        HStack(spacing: DesignSpacing.spacing1) {
            TextField("", value: $value, format: .number)
                .textFieldStyle(.plain)
                .font(.macDSBody.monospacedDigit())
                .foregroundStyle(palette.textPrimary)
                .multilineTextAlignment(.trailing)
                .focused($isFocused)
                .labelsHidden()
                .frame(width: 44)
                .onChange(of: value) { newValue in
                    value = min(range.upperBound, max(range.lowerBound, newValue))
                }

            Text(suffix)
                .font(.macDSCaption)
                .foregroundStyle(MacDS.Color.textSecondary)
        }
        .padding(.horizontal, DesignSpacing.spacing2)
        .padding(.vertical, DesignSpacing.spacing1)
        .background(palette.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: MacDS.Radius.standard))
        .overlay(
            RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                .stroke(
                    isFocused ? palette.inputFocusRingColor : palette.borderDefault,
                    lineWidth: isFocused ? 2 : 1
                )
                .allowsHitTesting(false)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue("\(value) \(suffix)")
    }
}

#if DEBUG
#Preview {
    struct PreviewHost: View {
        @State private var hours = 10
        @State private var minutes = 0

        var body: some View {
            PersonalWeeklyTargetInput(hours: $hours, minutes: $minutes)
                .padding()
                .background(MacDS.Color.backgroundPrimary)
                .environment(\.appUISurface, .mainWindow)
        }
    }
    return PreviewHost()
}
#endif
