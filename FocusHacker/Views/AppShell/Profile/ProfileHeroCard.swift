import SwiftUI

@available(macOS 14.0, *)
struct ProfileHeroCard: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: AppShellViewModel

    private static let layoutBreakpoint: CGFloat = 600
    private static let sidebarWidth: CGFloat = 210
    private static let badgeDiameterDesktop: CGFloat = 88
    private static let badgeDiameterMobile: CGFloat = 72

    private var palette: ProfileHeroPalette {
        ProfileHeroPalette.resolve(for: colorScheme)
    }

    private var appearance: FocusBadgeAppearance {
        FocusBadgeAppearance.forLevel(viewModel.playerLevel)
    }

    private var nextBadgeAppearance: FocusBadgeAppearance {
        if let next = FocusBadgeProgression.nextBadge(forTotalXP: viewModel.totalLifetimeXP) {
            return FocusBadgeAppearance.forBadge(next)
        }
        return appearance
    }

    private var unlockedLevelCount: Int {
        ProfileHeroMetrics.unlockedLevelCount(totalXP: viewModel.totalLifetimeXP)
    }

    private var isMaxLevel: Bool {
        ProfileHeroMetrics.isMaxBadge(totalXP: viewModel.totalLifetimeXP)
    }

    private var progressBarFraction: Double {
        if isMaxLevel {
            return 1
        }
        return ProfileHeroMetrics.xpProgressBarFraction(fraction: viewModel.badgeProgressFraction)
    }

    private var xpProgressLabel: String {
        ProfileHeroMetrics.xpProgressLabel(totalXP: viewModel.totalLifetimeXP)
    }

    private var xpProgressAmount: String {
        ProfileHeroMetrics.xpProgressAmountText(
            totalXP: viewModel.totalLifetimeXP,
            tierRelativeFraction: viewModel.badgeProgressFraction
        )
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            cardLayout(compact: false)
            cardLayout(compact: true)
        }
        .clipShape(RoundedRectangle(cornerRadius: MacDS.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: MacDS.Radius.card)
                .stroke(palette.cardBorder, lineWidth: ProfileHeroPalette.cardBorderWidth)
        )
        .profileHeroCardElevation(palette: palette)
        .environment(\.profileHeroPalette, palette)
        .preferredColorScheme(.dark)
        .redacted(reason: viewModel.profileIsLoading ? .placeholder : [])
        .accessibilityElement(children: .contain)
        .accessibilityLabel(heroAccessibilityLabel)
    }

    private func cardLayout(compact: Bool) -> some View {
        Group {
            if compact {
                VStack(spacing: 0) {
                    leftPanel
                    badgePanel(compact: true)
                }
            } else {
                HStack(alignment: .top, spacing: 0) {
                    leftPanel
                    badgePanel(compact: false)
                        .frame(width: Self.sidebarWidth)
                }
                .frame(minWidth: Self.layoutBreakpoint)
            }
        }
    }

    private var leftPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection
            statsRow
            progressSection
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
        .background(palette.leftPanel)
    }

    private func badgePanel(compact: Bool) -> some View {
        VStack(spacing: 12) {
            ProfileHero3DBadge(
                appearance: appearance,
                outerDiameter: compact ? Self.badgeDiameterMobile : Self.badgeDiameterDesktop
            )
            Text(viewModel.playerLevelTitle)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(palette.primaryText)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .truncationMode(.tail)
            Text(
                ProfileHeroMetrics.levelPositionLabel(
                    badgeLevel: viewModel.playerLevel,
                    unlockedCount: unlockedLevelCount
                )
            )
            .font(.system(size: 11))
            .foregroundStyle(palette.mutedLabel)
            .multilineTextAlignment(.center)
            ProfileHeroPipRow(
                unlockedCount: unlockedLevelCount,
                totalSegments: ProfileHeroMetrics.totalUnlockSegments,
                accent: appearance.accentColor,
                unfilledColor: appearance.primaryText.opacity(0.25)
            )
            if !isMaxLevel {
                ProfileHeroNextLevelPill(
                    nextTitle: viewModel.nextBadgeTitle,
                    appearance: nextBadgeAppearance
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .background {
            ZStack {
                palette.rightPanel
                appearance.badgePanelGradient()
            }
        }
        .overlay(alignment: .leading) {
            if !compact {
                Rectangle()
                    .fill(appearance.borderColor.opacity(FocusBadgeAppearance.badgePanelDividerOpacity))
                    .frame(width: 1)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(viewModel.profileDisplayName)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(palette.primaryText)
                .lineLimit(1)
                .truncationMode(.tail)
            Text(viewModel.profileHandleDisplay)
                .font(.system(size: 13))
                .foregroundStyle(palette.mutedLabel)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }

    private var statsRow: some View {
        HStack(alignment: .top, spacing: 8) {
            ProfileHeroStatBox(
                title: "Lifetime XP",
                systemImage: "chart.line.uptrend.xyaxis",
                value: ProfileHeroMetrics.formattedXP(viewModel.totalLifetimeXP)
            )
            ProfileHeroStatBox(
                title: "Best streak",
                systemImage: "flame.fill",
                value: "\(viewModel.longestDefaultWeeklyStreak) wks"
            )
            ProfileHeroStatBox(
                title: "Lifetime sessions",
                systemImage: "list.bullet.rectangle",
                value: ProfileHeroMetrics.formattedXP(viewModel.lifetimeEndedSessionCount)
            )
        }
    }

    private var progressSection: some View {
        ProfileHeroProgressBlock(
            label: xpProgressLabel,
            amountText: xpProgressAmount,
            fraction: progressBarFraction,
            accent: appearance.accentColor
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(xpProgressLabel), \(xpProgressAmount)")
    }

    private var heroAccessibilityLabel: String {
        var parts = [
            viewModel.profileDisplayName,
            viewModel.profileHandleDisplay,
            viewModel.playerLevelTitle,
            "Lifetime XP \(ProfileHeroMetrics.formattedXP(viewModel.totalLifetimeXP))",
            "Best streak \(viewModel.longestDefaultWeeklyStreak) weeks",
            "Lifetime sessions \(viewModel.lifetimeEndedSessionCount)",
            "\(xpProgressLabel), \(xpProgressAmount)",
            ProfileHeroMetrics.levelPositionLabel(
                badgeLevel: viewModel.playerLevel,
                unlockedCount: unlockedLevelCount
            ),
        ]
        if !isMaxLevel {
            parts.append("Next level \(viewModel.nextBadgeTitle)")
        }
        if let subtitle = appearance.subtitle {
            parts.append(subtitle)
        }
        return parts.joined(separator: ". ")
    }
}
