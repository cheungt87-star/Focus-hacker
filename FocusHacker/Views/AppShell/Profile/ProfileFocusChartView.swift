import Charts
import SwiftUI

@available(macOS 14.0, *)
struct ProfileFocusChartView: View {
    let period: ProfileChartPeriod
    let buckets: [FocusHoursChartBucket]
    let isLoading: Bool
    let focusHackerDailyTargetMinutes: Int
    let personalDailyTargetMinutes: Int

    private var calendar: Calendar { .current }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing3) {
            chartWithTargets
                .frame(minHeight: 200)
                .redacted(reason: isLoading ? .placeholder : [])

            targetLegend

            if buckets.isEmpty {
                Text("No focus data for this range yet.")
                    .font(.macDSBody)
                    .foregroundStyle(MacDS.Color.textSecondary)
            } else if !buckets.contains(where: { $0.focusMinutes > 0 }) {
                Text("Complete a focus session to see your trend here.")
                    .macDSHelperText()
            }
        }
    }

    private var chartWithTargets: some View {
        let dataMaxMinutes = buckets.map(\.focusMinutes).max() ?? 0
        let yPolicy = ProfileChartYAxisPolicyBuilder.make(
            period: period,
            dataMaxMinutes: dataMaxMinutes,
            targetMinutes: [focusHackerDailyTargetMinutes, personalDailyTargetMinutes]
        )
        let labelStride = period.xAxisLabelStrideDays
        let labelDates = xAxisLabelDates(from: buckets, strideDays: labelStride)
        let rangeStart = buckets.first?.periodStart ?? Date()
        let rangeEnd = calendar.date(byAdding: .day, value: 1, to: buckets.last?.periodStart ?? Date()) ?? Date()
        let barWidthRatio = period == .year ? 0.85 : 0.7

        return Chart {
            ForEach(buckets) { bucket in
                BarMark(
                    x: .value("Day", bucket.periodStart, unit: .day),
                    y: .value("Focus", bucket.focusMinutes),
                    width: .ratio(barWidthRatio)
                )
                .foregroundStyle(AnyShapeStyle(MacDS.Color.accentTeal.gradient))
                .cornerRadius(period == .week ? 5 : 2)
            }

            RuleMark(y: .value("FocusHacker target", focusHackerDailyTargetMinutes))
                .foregroundStyle(MacDS.Color.accentTeal.opacity(0.75))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))

            RuleMark(y: .value("Personal target", personalDailyTargetMinutes))
                .foregroundStyle(MacDS.Color.accentPurple.opacity(0.85))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
        }
        .chartXScale(domain: rangeStart...rangeEnd)
        .chartYScale(domain: 0...yPolicy.domainMaxMinutes)
        .chartYAxis {
            AxisMarks(position: .leading, values: yPolicy.tickValuesMinutes) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(MacDS.Color.border.opacity(0.6))
                if let minutes = value.as(Double.self) {
                    AxisValueLabel {
                        Text(yPolicy.formatLabel(minutes: minutes))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: labelDates) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel(centered: true, collisionResolution: .greedy) {
                        xAxisLabel(for: date)
                    }
                }
            }
        }
        .accessibilityLabel("Focus \(period.title) chart with daily targets")
    }

    private var targetLegend: some View {
        HStack(spacing: DesignSpacing.spacing6) {
            legendItem(
                color: MacDS.Color.accentTeal.opacity(0.75),
                label: "FocusHacker target (\(focusHackerDailyTargetMinutes) min/day)"
            )
            legendItem(
                color: MacDS.Color.accentPurple.opacity(0.85),
                label: "Personal target (\(personalDailyTargetMinutes) min/day)"
            )
        }
        .font(.caption2)
        .foregroundStyle(MacDS.Color.textSecondary)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: DesignSpacing.spacing2) {
            RoundedRectangle(cornerRadius: 1)
                .stroke(color, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                .frame(width: 20, height: 2)
            Text(label)
        }
    }

    private func xAxisLabelDates(
        from buckets: [FocusHoursChartBucket],
        strideDays: Int
    ) -> [Date] {
        guard !buckets.isEmpty else { return [] }
        let stride = max(1, strideDays)
        var dates = buckets.enumerated().compactMap { index, bucket -> Date? in
            index % stride == 0 ? bucket.periodStart : nil
        }
        if let last = buckets.last?.periodStart, dates.last != last {
            dates.append(last)
        }
        return dates
    }

    private func xAxisLabel(for date: Date) -> some View {
        VStack(spacing: 0) {
            Text(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                .font(.caption2.weight(.semibold))
            Text("\(calendar.component(.day, from: date))")
                .font(.caption2)
        }
        .foregroundStyle(MacDS.Color.textSecondary)
    }
}

#if DEBUG
@available(macOS 14.0, *)
#Preview("Week") {
    ProfileFocusChartView(
        period: .week,
        buckets: ProfileFocusChartMockData.buckets(for: .week),
        isLoading: false,
        focusHackerDailyTargetMinutes: ProfileChartTargets.mockFocusHackerDailyMinutes,
        personalDailyTargetMinutes: ProfileChartTargets.mockPersonalDailyMinutes
    )
    .frame(width: 480, height: 280)
    .padding()
}

@available(macOS 14.0, *)
#Preview("Month") {
    ProfileFocusChartView(
        period: .month,
        buckets: ProfileFocusChartMockData.buckets(for: .month),
        isLoading: false,
        focusHackerDailyTargetMinutes: ProfileChartTargets.mockFocusHackerDailyMinutes,
        personalDailyTargetMinutes: ProfileChartTargets.mockPersonalDailyMinutes
    )
    .frame(width: 480, height: 280)
    .padding()
}

@available(macOS 14.0, *)
#Preview("6 mo") {
    ProfileFocusChartView(
        period: .sixMonths,
        buckets: ProfileFocusChartMockData.buckets(for: .sixMonths),
        isLoading: false,
        focusHackerDailyTargetMinutes: ProfileChartTargets.mockFocusHackerDailyMinutes,
        personalDailyTargetMinutes: ProfileChartTargets.mockPersonalDailyMinutes
    )
    .frame(width: 480, height: 280)
    .padding()
}

@available(macOS 14.0, *)
#Preview("Year") {
    ProfileFocusChartView(
        period: .year,
        buckets: ProfileFocusChartMockData.buckets(for: .year),
        isLoading: false,
        focusHackerDailyTargetMinutes: ProfileChartTargets.mockFocusHackerDailyMinutes,
        personalDailyTargetMinutes: ProfileChartTargets.mockPersonalDailyMinutes
    )
    .frame(width: 480, height: 280)
    .padding()
}
#endif
