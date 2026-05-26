import SwiftUI

@available(macOS 14.0, *)
struct AnalyticsSummaryStatCardsView: View {
    let summary: AnalyticsMonthSummary

    private let statCardColumns = Array(
        repeating: GridItem(.flexible(), spacing: 10),
        count: 4
    )

    var body: some View {
        LazyVGrid(columns: statCardColumns, spacing: 10) {
            statCard(
                label: "SESSIONS",
                value: "\(summary.sessionCount)",
                sublabel: summary.monthSubtitle,
                valueColor: Color.fhColorDSSlate
            )
            statCard(
                label: "FOCUS TIME",
                value: AnalyticsSessionFormatting.focusDuration(minutes: summary.totalFocusMinutes),
                sublabel: summary.monthSubtitle,
                valueColor: Color.fhColorMint
            )
            statCard(
                label: "XP EARNED",
                value: "\(summary.totalXP)",
                sublabel: summary.monthSubtitle,
                valueColor: Color.fhColorGold
            )
            statCard(
                label: "COMPLETION",
                value: AnalyticsSessionFormatting.completionPercentLabel(summary.completionRatePercent),
                sublabel: summary.completionSubLabel,
                valueColor: Color.fhColorEmber
            )
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Monthly summary statistics")
    }

    private func statCard(
        label: String,
        value: String,
        sublabel: String,
        valueColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing2) {
            Text(label)
                .font(.macDSLabel)
                .foregroundStyle(MacDS.Color.textSecondary)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(valueColor)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(sublabel)
                .font(.macDSCaption)
                .foregroundStyle(MacDS.Color.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
        .padding(DesignSpacing.spacing5)
        .background {
            RoundedRectangle(cornerRadius: MacDS.Radius.card)
                .fill(MacDS.Color.cardBackground)
        }
        .overlay(
            RoundedRectangle(cornerRadius: MacDS.Radius.card)
                .stroke(MacDS.Color.border, lineWidth: 1)
        )
        .macDSCardShadow()
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
    }
}
