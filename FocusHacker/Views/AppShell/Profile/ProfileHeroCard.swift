import SwiftUI

@available(macOS 14.0, *)
struct ProfileHeroCard: View {
    @ObservedObject var viewModel: AppShellViewModel

    var body: some View {
        MacDSHeroCard {
            ViewThatFits(in: .horizontal) {
                wideLayout
                narrowLayout
            }
        }
        .redacted(reason: viewModel.profileIsLoading ? .placeholder : [])
        .accessibilityElement(children: .combine)
        .accessibilityLabel(heroAccessibilityLabel)
    }

    private var heroAccessibilityLabel: String {
        "Welcome back, \(viewModel.profileDisplayName). Lifetime XP \(viewModel.totalLifetimeXP). Longest streak \(ProfileHeroPlaceholder.mockLongestStreakWeeks) weeks. Current streak \(ProfileHeroPlaceholder.mockCurrentStreakWeeks) weeks. Progress to \(ProfileHeroPlaceholder.nextLevelTitle) \(ProfileHeroPlaceholder.mockProgressPercentDisplay) percent. Level \(viewModel.playerLevelTitle)."
    }

    private var wideLayout: some View {
        HStack(alignment: .center, spacing: DesignSpacing.spacing8) {
            leftContent
                .frame(maxWidth: .infinity, alignment: .leading)
            badgeColumn
                .frame(width: 200)
        }
    }

    private var narrowLayout: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing6) {
            leftContent
            badgeColumn
                .frame(maxWidth: .infinity)
        }
    }

    private var leftContent: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing6) {
            VStack(alignment: .leading, spacing: DesignSpacing.spacing2) {
                Text("Welcome back")
                    .font(.macDSLabel)
                    .foregroundStyle(.white.opacity(0.7))
                Text(viewModel.profileDisplayName)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                Text(viewModel.profileHandleDisplay)
                    .font(.macDSBody)
                    .foregroundStyle(.white.opacity(0.75))
            }

            HStack(alignment: .top, spacing: DesignSpacing.spacing6) {
                xpStatColumn
                longestStreakStatColumn
                currentStreakStatColumn
            }

            levelProgressSection
        }
    }

    private var xpStatColumn: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing2) {
            Label("Lifetime XP", systemImage: "chart.line.uptrend.xyaxis")
                .font(.macDSLabel)
                .foregroundStyle(.white.opacity(0.7))
                .labelStyle(.titleAndIcon)
            Text("\(viewModel.totalLifetimeXP.formatted())")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(MacDS.Color.accentTealLighter)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }

    private var longestStreakStatColumn: some View {
        weekStreakStatColumn(
            title: "Longest streak",
            systemImage: "flame.fill",
            weeks: ProfileHeroPlaceholder.mockLongestStreakWeeks
        )
    }

    private var currentStreakStatColumn: some View {
        weekStreakStatColumn(
            title: "Current streak",
            systemImage: "bolt.fill",
            weeks: ProfileHeroPlaceholder.mockCurrentStreakWeeks
        )
    }

    private func weekStreakStatColumn(title: String, systemImage: String, weeks: Int) -> some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing2) {
            Label(title, systemImage: systemImage)
                .font(.macDSLabel)
                .foregroundStyle(.white.opacity(0.7))
                .labelStyle(.titleAndIcon)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(weeks)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(MacDS.Color.accentOrange)
                    .monospacedDigit()
                Text("w")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(MacDS.Color.accentOrange.opacity(0.9))
            }
            Text("weeks in a row")
                .font(.macDSCaption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .accessibilityElement(children: .combine)
    }

    private var levelProgressSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing2) {
            HStack {
                Text("Progress to \(ProfileHeroPlaceholder.nextLevelTitle)")
                    .font(.macDSLabel)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Text("\(ProfileHeroPlaceholder.mockXPGap.formatted()) XP to go")
                    .font(.macDSCaption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.75))
                    .monospacedDigit()
            }
            MacDSProgressBar(
                fraction: ProfileHeroPlaceholder.mockProgressFraction,
                tint: MacDS.Color.accentTealLighter
            )
            Text("\(ProfileHeroPlaceholder.mockProgressPercentDisplay)% complete")
                .font(.macDSCaption)
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private var badgeColumn: some View {
        VStack(spacing: DesignSpacing.spacing3) {
            ZStack {
                Circle()
                    .fill(MacDS.Color.accentTeal.opacity(0.35))
                    .frame(width: 140, height: 140)
                Image(systemName: "trophy.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(MacDS.Color.accentOrange)
            }
            Text(viewModel.playerLevelTitle)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text("Achievement level")
                .font(.macDSCaption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }
}
