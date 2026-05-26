import SwiftUI

// MARK: - Formatting

enum ProfileWeeklyProgressFormatting {
    static let streakExplainer = "Weeks in a row hitting your goals"

    static func streakWeeksDisplay(_ weeks: Int) -> String {
        "\(weeks)"
    }

    static func streakUnitLabel(weeks: Int) -> String {
        weeks == 1 ? "week" : "weeks"
    }

    static func focusMinutesValueText(minutes: Int) -> String {
        "\(minutes)"
    }

    static func goalMinutesToGoText(remainingMinutes: Int) -> String {
        "\(remainingMinutes) min to go"
    }

    static func goalPercentText(percentDisplay: Int) -> String {
        "\(percentDisplay)%"
    }

    static func goalProgressBarFraction(fraction: Double) -> Double {
        ProfileHeroMetrics.xpProgressBarFraction(fraction: fraction)
    }

    static func streakAccessibilityLabel(weeks: Int) -> String {
        "Week streak, \(weeks) \(streakUnitLabel(weeks: weeks)). \(streakExplainer)"
    }

    static func focusMetricAccessibilityLabel(minutes: Int) -> String {
        "Focus hours so far this week, \(minutes) minutes"
    }

    static func goalAccessibilityLabel(
        title: String,
        percentDisplay: Int,
        remainingMinutes: Int
    ) -> String {
        "\(title), \(percentDisplay) percent complete, \(remainingMinutes) minutes to go"
    }
}

// MARK: - Layout constants

enum WeekProgressCardLayout {
    static let cardPadding: CGFloat = DesignSpacing.spacing8
    static let sidebarWidth: CGFloat = 220
    static let dividerThickness: CGFloat = 0.5
    static let sectionSpacing: CGFloat = 28
    static let goalsSubheaderSpacing: CGFloat = 28
    static let goalBlockSpacing: CGFloat = 40
    static let streakHeaderToCircleSpacing: CGFloat = 24
    static let streakCircleToExplainerSpacing: CGFloat = 20
}

enum WeekProgressGoalLayout {
    static let hackerBarHeight: CGFloat = 8
    static let personalBarHeight: CGFloat = 5
    static let hackerLabelToBarSpacing: CGFloat = DesignSpacing.spacing4
    static let personalLabelToBarSpacing: CGFloat = DesignSpacing.spacing3
}

enum WeekProgressStreakLayoutMetrics {
    static let sidebarHorizontalPadding: CGFloat = DesignSpacing.spacing8
    static let sidebarVerticalPadding: CGFloat = DesignSpacing.spacing8
    static let explainerMaxWidth: CGFloat = 180
}

// MARK: - Palette

struct ProfileWeeklyProgressPalette: Equatable, Sendable {
    let cardBackground: Color
    let textPrimary: Color
    let textSecondary: Color
    let textMuted: Color
    let trackBackground: Color
    let divider: Color
    let streakSidebarBackground: Color
    let streakFill: Color
    let streakBorder: Color
    let hackerAccent: Color
    let personalAccent: Color

    static func resolve(for colorScheme: ColorScheme) -> ProfileWeeklyProgressPalette {
        ProfileWeeklyProgressPalette(
            cardBackground: MacDS.Resolved.cardBackground(for: colorScheme),
            textPrimary: MacDS.Resolved.textPrimary(for: colorScheme),
            textSecondary: MacDS.Resolved.textSecondary(for: colorScheme),
            textMuted: MacDS.Resolved.textTertiary(for: colorScheme),
            trackBackground: Color.macDSResolved(light: 0xF3F4F6, dark: 0x3A3A3C, for: colorScheme),
            divider: Color.macDSResolved(light: 0xE5E7EB, dark: 0x48484A, for: colorScheme),
            streakSidebarBackground: Color.macDSResolved(light: 0xF9FAFB, dark: 0x323234, for: colorScheme),
            streakFill: Color(hex: 0xFBBF24),
            streakBorder: Color(hex: 0xF59E0B),
            hackerAccent: Color(hex: 0x2563EB),
            personalAccent: Color(hex: 0xE9D5FF)
        )
    }
}

// MARK: - Section headers

@available(macOS 14.0, *)
struct WeekProgressSectionHeader: View {
    let title: String
    let fontSize: CGFloat
    let palette: ProfileWeeklyProgressPalette
    var wideTracking: Bool = false

    var body: some View {
        Text(title)
            .font(.system(size: fontSize, weight: .medium))
            .kerning(wideTracking ? 1.2 : 0.4)
            .textCase(.uppercase)
            .foregroundStyle(palette.textSecondary)
    }
}

// MARK: - Focus metric

@available(macOS 14.0, *)
struct WeekProgressFocusMetric: View {
    let focusMinutes: Int
    let palette: ProfileWeeklyProgressPalette

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Focus hours so far this week")
                .font(.system(size: 11, weight: .medium))
                .textCase(.uppercase)
                .foregroundStyle(palette.textMuted)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(ProfileWeeklyProgressFormatting.focusMinutesValueText(minutes: focusMinutes))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(palette.textPrimary)
                    .monospacedDigit()

                Text("min")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(ProfileWeeklyProgressFormatting.focusMetricAccessibilityLabel(minutes: focusMinutes))
    }
}

// MARK: - Streak ring

@available(macOS 14.0, *)
struct WeekProgressStreakRing: View {
    static let diameter: CGFloat = 110
    static let ringStrokeWidth: CGFloat = 2

    let streakWeeks: Int
    let palette: ProfileWeeklyProgressPalette

    var body: some View {
        ZStack {
            Circle()
                .fill(palette.streakFill)

            Circle()
                .strokeBorder(palette.streakBorder, lineWidth: Self.ringStrokeWidth)

            Text(ProfileWeeklyProgressFormatting.streakWeeksDisplay(streakWeeks))
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(Color.white)
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(width: Self.diameter, height: Self.diameter)
        .accessibilityHidden(true)
    }
}

// MARK: - Streak hero

@available(macOS 14.0, *)
struct WeekProgressStreakHero: View {
    let streakWeeks: Int
    let palette: ProfileWeeklyProgressPalette

    var body: some View {
        VStack(spacing: 0) {
            WeekProgressSectionHeader(
                title: "Week streak",
                fontSize: 11,
                palette: palette,
                wideTracking: true
            )

            Spacer()
                .frame(height: WeekProgressCardLayout.streakHeaderToCircleSpacing)

            WeekProgressStreakRing(streakWeeks: streakWeeks, palette: palette)

            Spacer()
                .frame(height: WeekProgressCardLayout.streakCircleToExplainerSpacing)

            Text(ProfileWeeklyProgressFormatting.streakExplainer)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: WeekProgressStreakLayoutMetrics.explainerMaxWidth)
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(ProfileWeeklyProgressFormatting.streakAccessibilityLabel(weeks: streakWeeks))
    }
}

// MARK: - Goal rows

enum WeekProgressGoalEmphasis: Equatable, Sendable {
    case hero
    case subtle
}

@available(macOS 14.0, *)
struct WeekProgressGoalRow: View {
    let title: String
    let remainingMinutes: Int
    let fraction: Double
    let percentDisplay: Int
    let accent: Color
    let palette: ProfileWeeklyProgressPalette
    let emphasis: WeekProgressGoalEmphasis

    private var barHeight: CGFloat {
        emphasis == .hero ? WeekProgressGoalLayout.hackerBarHeight : WeekProgressGoalLayout.personalBarHeight
    }

    private var labelToBarSpacing: CGFloat {
        emphasis == .hero
            ? WeekProgressGoalLayout.hackerLabelToBarSpacing
            : WeekProgressGoalLayout.personalLabelToBarSpacing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: labelToBarSpacing) {
            HStack(alignment: .firstTextBaseline, spacing: DesignSpacing.spacing2) {
                Text(title)
                    .font(titleFont)
                    .foregroundStyle(titleColor)

                Spacer(minLength: DesignSpacing.spacing2)

                HStack(alignment: .firstTextBaseline, spacing: DesignSpacing.spacing2) {
                    Text(ProfileWeeklyProgressFormatting.goalPercentText(percentDisplay: percentDisplay))
                        .font(percentFont)
                        .foregroundStyle(palette.textMuted)

                    Text(ProfileWeeklyProgressFormatting.goalMinutesToGoText(remainingMinutes: remainingMinutes))
                        .font(metricFont)
                        .foregroundStyle(metricColor)
                        .monospacedDigit()
                }
            }

            WeekProgressGoalBar(
                fraction: fraction,
                accent: accent,
                trackBackground: palette.trackBackground,
                height: barHeight
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            ProfileWeeklyProgressFormatting.goalAccessibilityLabel(
                title: title,
                percentDisplay: percentDisplay,
                remainingMinutes: remainingMinutes
            )
        )
    }

    private var titleFont: Font {
        emphasis == .hero
            ? .system(size: 15, weight: .bold)
            : .system(size: 13, weight: .regular)
    }

    private var titleColor: Color {
        emphasis == .hero ? palette.textPrimary : palette.textMuted
    }

    private var percentFont: Font {
        emphasis == .hero
            ? .system(size: 12, weight: .regular)
            : .system(size: 11, weight: .regular)
    }

    private var metricFont: Font {
        emphasis == .hero
            ? .system(size: 14, weight: .semibold)
            : .system(size: 12, weight: .regular)
    }

    private var metricColor: Color {
        emphasis == .hero ? palette.textPrimary : palette.textMuted
    }
}

@available(macOS 14.0, *)
struct WeekProgressGoalBar: View {
    let fraction: Double
    let accent: Color
    let trackBackground: Color
    let height: CGFloat

    private var displayFraction: Double {
        ProfileWeeklyProgressFormatting.goalProgressBarFraction(fraction: fraction)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(trackBackground)

                Capsule()
                    .fill(accent)
                    .frame(width: max(0, geometry.size.width * displayFraction))
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}
