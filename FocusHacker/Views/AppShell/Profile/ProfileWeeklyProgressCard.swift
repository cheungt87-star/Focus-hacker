import SwiftUI

@available(macOS 14.0, *)
struct ProfileWeeklyProgressCard: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: AppShellViewModel

    private static let layoutBreakpoint: CGFloat = 600

    private var palette: ProfileWeeklyProgressPalette {
        ProfileWeeklyProgressPalette.resolve(for: colorScheme)
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            cardLayout(compact: false)
            cardLayout(compact: true)
        }
        .background {
            RoundedRectangle(cornerRadius: MacDS.Radius.card)
                .fill(palette.cardBackground)
        }
        .clipShape(RoundedRectangle(cornerRadius: MacDS.Radius.card))
        .macDSCardShadow(elevated: false)
        .redacted(reason: viewModel.profileIsLoading ? .placeholder : [])
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Current week progress")
    }

    @ViewBuilder
    private func cardLayout(compact: Bool) -> some View {
        if compact {
            VStack(spacing: 0) {
                focusAndGoalsPanel
                sectionDivider(horizontal: true)
                streakSidebar
            }
        } else {
            HStack(alignment: .top, spacing: 0) {
                focusAndGoalsPanel
                sectionDivider(horizontal: false)
                streakSidebar
            }
            .frame(minWidth: Self.layoutBreakpoint)
        }
    }

    private var focusAndGoalsPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            WeekProgressSectionHeader(
                title: "Focus time this week",
                fontSize: 12,
                palette: palette
            )

            Spacer()
                .frame(height: WeekProgressCardLayout.sectionSpacing)

            WeekProgressFocusMetric(
                focusMinutes: viewModel.currentWeekFocusMinutes,
                palette: palette
            )

            Spacer()
                .frame(height: WeekProgressCardLayout.sectionSpacing)

            WeekProgressSectionHeader(
                title: "Progress towards goals",
                fontSize: 12,
                palette: palette
            )

            Spacer()
                .frame(height: WeekProgressCardLayout.goalsSubheaderSpacing)

            VStack(alignment: .leading, spacing: WeekProgressCardLayout.goalBlockSpacing) {
                WeekProgressGoalRow(
                    title: "Hacker Goal",
                    remainingMinutes: viewModel.hackerWeeklyMinutesRemaining,
                    fraction: viewModel.hackerWeeklyProgressFraction,
                    percentDisplay: viewModel.hackerWeeklyMinutesPercentDisplay,
                    accent: palette.hackerAccent,
                    palette: palette,
                    emphasis: .hero
                )

                WeekProgressGoalRow(
                    title: "Personal Goal",
                    remainingMinutes: viewModel.personalWeeklyMinutesRemaining,
                    fraction: viewModel.personalWeeklyProgressFraction,
                    percentDisplay: viewModel.personalWeeklyMinutesPercentDisplay,
                    accent: palette.personalAccent,
                    palette: palette,
                    emphasis: .subtle
                )
            }
        }
        .padding(WeekProgressCardLayout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var streakSidebar: some View {
        WeekProgressStreakHero(
            streakWeeks: viewModel.defaultWeeklyStreak,
            palette: palette
        )
        .padding(.horizontal, WeekProgressStreakLayoutMetrics.sidebarHorizontalPadding)
        .padding(.vertical, WeekProgressStreakLayoutMetrics.sidebarVerticalPadding)
        .frame(width: WeekProgressCardLayout.sidebarWidth)
        .frame(maxHeight: .infinity)
        .background(palette.streakSidebarBackground)
    }

    private func sectionDivider(horizontal: Bool) -> some View {
        Group {
            if horizontal {
                Rectangle()
                    .fill(palette.divider)
                    .frame(height: WeekProgressCardLayout.dividerThickness)
            } else {
                Rectangle()
                    .fill(palette.divider)
                    .frame(width: WeekProgressCardLayout.dividerThickness)
            }
        }
    }
}
