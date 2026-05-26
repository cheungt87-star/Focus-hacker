import Charts
import SwiftUI

@available(macOS 14.0, *)
struct ProfileFocusChartView: View {
    private static let placeholderBarMinutes = 12.0

    let period: ProfileChartPeriod
    let buckets: [FocusHoursChartBucket]
    let isLoading: Bool
    let focusHackerDailyTargetMinutes: Int
    let personalDailyTargetMinutes: Int
    let lastUpdated: Date?

    @Binding var selectedBucket: FocusHoursChartBucket?

    @State private var selectedWeekIndex: Int?
    @State private var selectedYearIndex: Int?
    @State private var selectedDay: Date?

    private var calendar: Calendar { .current }

    private var yPolicy: ProfileChartYAxisPolicy {
        let dataMaxMinutes = buckets.map(\.focusMinutes).max() ?? 0
        return ProfileChartYAxisPolicyBuilder.make(
            period: period,
            dataMaxMinutes: dataMaxMinutes,
            targetMinutes: [focusHackerDailyTargetMinutes, personalDailyTargetMinutes]
        )
    }

    private var showsTargetGuides: Bool {
        period != .year
    }

    /// Forces Swift Charts to redraw when bucket values change (stable day ids alone are not enough).
    private var chartRenderIdentity: String {
        buckets.map { "\($0.id)-\($0.focusMinutes)-\($0.xpEarned)" }.joined(separator: "|")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing3) {
            if showsTargetGuides {
                targetLegend
            }

            ZStack(alignment: .bottomTrailing) {
                Group {
                    switch period {
                    case .week:
                        weekChart
                    case .year:
                        yearChart
                    case .month:
                        dailyChart
                    }
                }
                .frame(minHeight: 200)
                .redacted(reason: isLoading ? .placeholder : [])

                lastUpdatedLabel
            }

            if buckets.isEmpty {
                Text("No focus data for this range yet.")
                    .font(.macDSBody)
                    .foregroundStyle(MacDS.Color.textSecondary)
            } else if !buckets.contains(where: { $0.focusMinutes > 0 }) {
                Text("Complete a focus session to see your trend here.")
                    .macDSHelperText()
            }
        }
        .onChange(of: period) { _, _ in
            clearSelection()
        }
        .onChange(of: buckets.map(\.id)) { _, _ in
            clearSelection()
        }
        .onChange(of: chartRenderIdentity) { _, identity in
            // #region agent log
            let mondayMinutes = buckets.first?.focusMinutes ?? -1
            DebugSessionLog5cee87.write(
                hypothesisId: "H15",
                location: "ProfileFocusChartView.chartRenderIdentity",
                message: "chart_render",
                data: [
                    "period": period.rawValue,
                    "mondayMinutes": "\(mondayMinutes)",
                    "identityLength": "\(identity.count)",
                    "bucketCount": "\(buckets.count)",
                ],
                runId: "post-fix"
            )
            // #endregion
            clearSelection()
        }
        .onChange(of: selectedWeekIndex) { _, index in
            syncSelectionFromWeekIndex(index)
        }
        .onChange(of: selectedYearIndex) { _, index in
            syncSelectionFromYearIndex(index)
        }
        .onChange(of: selectedDay) { _, day in
            syncSelectionFromDay(day)
        }
    }

    private func clearSelection() {
        selectedWeekIndex = nil
        selectedYearIndex = nil
        selectedDay = nil
        selectedBucket = nil
    }

    private func syncSelectionFromWeekIndex(_ index: Int?) {
        guard period == .week else { return }
        guard let index, buckets.indices.contains(index) else {
            selectedBucket = nil
            return
        }
        selectedBucket = buckets[index]
    }

    private func syncSelectionFromYearIndex(_ index: Int?) {
        guard period == .year else { return }
        guard let index, buckets.indices.contains(index) else {
            selectedBucket = nil
            return
        }
        selectedBucket = buckets[index]
    }

    private func syncSelectionFromDay(_ day: Date?) {
        guard period == .month else { return }
        guard let day else {
            selectedBucket = nil
            return
        }
        selectedBucket = buckets.first { calendar.isDate($0.periodStart, inSameDayAs: day) }
    }

    private var weekChart: some View {
        let barWidth = barWidthRatio(for: .week)
        let cornerRadius = barCornerRadius(for: .week)
        let xDomainEnd = max(0, Double(buckets.count - 1)) + 0.5

        return Chart {
            ForEach(Array(buckets.enumerated()), id: \.element.id) { index, bucket in
                if bucket.focusMinutes == 0 {
                    placeholderBarMark(x: index, widthRatio: barWidth, cornerRadius: cornerRadius)
                }

                if bucket.focusMinutes > 0 {
                    BarMark(
                        x: .value("Day", index),
                        y: .value("Focus", bucket.focusMinutes),
                        width: .ratio(barWidth)
                    )
                    .foregroundStyle(barFill(for: bucket.focusMinutes))
                    .cornerRadius(cornerRadius)
                }
            }

            targetRuleMarks
        }
        .chartPlotStyle { plotArea in
            plotArea
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 8)
        }
        .chartXScale(domain: -0.5...xDomainEnd)
        .chartYScale(domain: 0...yPolicy.domainMaxMinutes)
        .chartXSelection(value: $selectedWeekIndex)
        .chartYAxis(content: yAxisContent)
        .chartXAxis {
            AxisMarks(values: Array(0..<buckets.count)) { value in
                if let index = value.as(Int.self), buckets.indices.contains(index) {
                    AxisValueLabel(centered: true, collisionResolution: .disabled) {
                        xAxisLabel(for: buckets[index].periodStart, period: .week)
                    }
                }
            }
        }
        .chartOverlay { proxy in
            chartTooltipOverlay(proxy: proxy)
        }
        .accessibilityLabel("Focus \(period.title) chart with daily targets")
        .accessibilityValue(chartAccessibilityValue)
        .id(chartRenderIdentity)
    }

    private var yearChart: some View {
        let barWidth = barWidthRatio(for: .year)
        let cornerRadius = barCornerRadius(for: .year)
        let xDomainEnd = max(0, Double(buckets.count - 1)) + 0.5

        return Chart {
            ForEach(Array(buckets.enumerated()), id: \.element.id) { index, bucket in
                if bucket.focusMinutes == 0 {
                    placeholderBarMark(x: index, widthRatio: barWidth, cornerRadius: cornerRadius)
                }

                if bucket.focusMinutes > 0 {
                    BarMark(
                        x: .value("Month", index),
                        y: .value("Focus", bucket.focusMinutes),
                        width: .ratio(barWidth)
                    )
                    .foregroundStyle(barFill(for: bucket.focusMinutes, period: .year))
                    .cornerRadius(cornerRadius)
                }
            }
        }
        .chartPlotStyle { plotArea in
            plotArea
                .padding(.leading, 40)
                .padding(.trailing, 18)
                .padding(.top, 12)
                .padding(.bottom, 8)
        }
        .chartXScale(domain: -0.5...xDomainEnd)
        .chartYScale(domain: 0...yPolicy.domainMaxMinutes)
        .chartXSelection(value: $selectedYearIndex)
        .chartYAxis(content: yAxisContent)
        .chartXAxis {
            AxisMarks(values: Array(0..<buckets.count)) { value in
                if let index = value.as(Int.self), buckets.indices.contains(index) {
                    AxisValueLabel(centered: true, collisionResolution: .greedy) {
                        Text(buckets[index].label)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(MacDS.Color.textSecondary)
                    }
                }
            }
        }
        .chartOverlay { proxy in
            chartTooltipOverlay(proxy: proxy)
        }
        .accessibilityLabel("Focus \(period.title) chart")
        .accessibilityValue(chartAccessibilityValue)
        .id(chartRenderIdentity)
    }

    private var dailyChart: some View {
        let xAxisDates = ProfileChartAxisLabels.xAxisDates(period: period, buckets: buckets, calendar: calendar)
        let rangeStart = buckets.first?.periodStart ?? Date()
        let rangeEnd = calendar.date(byAdding: .day, value: 1, to: buckets.last?.periodStart ?? Date()) ?? Date()
        let barWidth = barWidthRatio(for: period)
        let cornerRadius = barCornerRadius(for: period)

        return Chart {
            ForEach(buckets) { bucket in
                if bucket.focusMinutes == 0 {
                    placeholderBarMark(x: bucket.periodStart, widthRatio: barWidth, cornerRadius: cornerRadius)
                }

                if bucket.focusMinutes > 0 {
                    BarMark(
                        x: .value("Day", bucket.periodStart, unit: .day),
                        y: .value("Focus", bucket.focusMinutes),
                        width: .ratio(barWidth)
                    )
                    .foregroundStyle(barFill(for: bucket.focusMinutes))
                    .cornerRadius(cornerRadius)
                }
            }

            targetRuleMarks
        }
        .chartPlotStyle { plotArea in
            plotArea
                .padding(.leading, 40)
                .padding(.trailing, 18)
                .padding(.top, 12)
                .padding(.bottom, 8)
        }
        .chartXScale(domain: rangeStart...rangeEnd)
        .chartYScale(domain: 0...yPolicy.domainMaxMinutes)
        .chartXSelection(value: $selectedDay)
        .chartYAxis(content: yAxisContent)
        .chartXAxis {
            AxisMarks(preset: .aligned, values: xAxisDates) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel(centered: true, collisionResolution: .greedy) {
                        xAxisLabel(for: date, period: period)
                    }
                }
            }
        }
        .chartOverlay { proxy in
            chartTooltipOverlay(proxy: proxy)
        }
        .accessibilityLabel("Focus \(period.title) chart with daily targets")
        .accessibilityValue(chartAccessibilityValue)
        .id(chartRenderIdentity)
    }

    @ChartContentBuilder
    private func placeholderBarMark(x: Int, widthRatio: Double, cornerRadius: CGFloat) -> some ChartContent {
        BarMark(
            x: .value("Day", x),
            y: .value("Focus", Self.placeholderBarMinutes),
            width: .ratio(widthRatio)
        )
        .foregroundStyle(MacDS.Color.accentTeal.opacity(0.10))
        .cornerRadius(cornerRadius)
    }

    @ChartContentBuilder
    private func placeholderBarMark(x: Date, widthRatio: Double, cornerRadius: CGFloat) -> some ChartContent {
        BarMark(
            x: .value("Day", x, unit: .day),
            y: .value("Focus", Self.placeholderBarMinutes),
            width: .ratio(widthRatio)
        )
        .foregroundStyle(MacDS.Color.accentTeal.opacity(0.10))
        .cornerRadius(cornerRadius)
    }

    @ChartContentBuilder
    private var targetRuleMarks: some ChartContent {
        RuleMark(y: .value("Target", focusHackerDailyTargetMinutes))
            .foregroundStyle(MacDS.Color.accentTeal.opacity(0.85))
            .lineStyle(StrokeStyle(lineWidth: 2.5))

        RuleMark(y: .value("Stretch", personalDailyTargetMinutes))
            .foregroundStyle(MacDS.Color.accentTealLight)
            .lineStyle(StrokeStyle(lineWidth: 2.5, dash: [5, 4]))
    }

    private func yAxisContent() -> some AxisContent {
        AxisMarks(preset: .inset, position: .leading, values: yPolicy.tickValuesMinutes) { value in
            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                .foregroundStyle(MacDS.Color.border.opacity(0.35))
            if let minutes = value.as(Double.self) {
                AxisValueLabel(anchor: .trailing, collisionResolution: .disabled) {
                    Text(yPolicy.formatLabel(minutes: minutes))
                        .font(.system(size: 10))
                        .foregroundStyle(MacDS.Color.textSecondary.opacity(0.65))
                }
            }
        }
    }

    private func barFill(for focusMinutes: Int, period: ProfileChartPeriod? = nil) -> Color {
        let resolvedPeriod = period ?? self.period
        let comparisonTarget: Int
        switch resolvedPeriod {
        case .year:
            comparisonTarget = personalDailyTargetMinutes * 30
        case .week, .month:
            comparisonTarget = personalDailyTargetMinutes
        }
        if focusMinutes > comparisonTarget {
            return MacDS.Color.accentTeal
        }
        return MacDS.Color.accentTeal.opacity(0.55)
    }

    private func barWidthRatio(for period: ProfileChartPeriod) -> Double {
        switch period {
        case .week: return 0.82
        case .month: return 0.52
        case .year: return 0.72
        }
    }

    private func barCornerRadius(for period: ProfileChartPeriod) -> CGFloat {
        switch period {
        case .week: return 7
        case .month: return 4
        case .year: return 5
        }
    }

    @ViewBuilder
    private func chartTooltipOverlay(proxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            if let bucket = selectedBucket,
               let plotFrame = proxy.plotFrame,
               let xPosition = tooltipXPosition(for: bucket, proxy: proxy, plotFrame: plotFrame, geometry: geometry) {
                let plotOrigin = geometry[plotFrame].origin
                let anchorX = plotOrigin.x + xPosition
                let anchorY = plotOrigin.y + 8

                chartTooltip(for: bucket)
                    .position(x: min(max(anchorX, 56), geometry.size.width - 56), y: anchorY)
            }
        }
    }

    private func tooltipXPosition(
        for bucket: FocusHoursChartBucket,
        proxy: ChartProxy,
        plotFrame: Anchor<CGRect>,
        geometry: GeometryProxy
    ) -> CGFloat? {
        if period == .week || period == .year,
           let index = buckets.firstIndex(where: { $0.id == bucket.id }) {
            return proxy.position(forX: index)
        }
        return proxy.position(forX: bucket.periodStart)
    }

    private func chartTooltip(for bucket: FocusHoursChartBucket) -> some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing1) {
            Text(ProfileChartAxisLabels.tooltipFocusDuration(minutes: bucket.focusMinutes))
                .font(.caption.weight(.semibold))
                .foregroundStyle(MacDS.Color.textPrimary)
            Text(ProfileChartAxisLabels.tooltipDateLabel(for: bucket.periodStart, period: period, calendar: calendar))
                .font(.caption)
                .foregroundStyle(MacDS.Color.textSecondary)
        }
        .padding(.horizontal, DesignSpacing.spacing3)
        .padding(.vertical, DesignSpacing.spacing2)
        .background(
            RoundedRectangle(cornerRadius: MacDS.Radius.standard - 2)
                .fill(MacDS.Color.cardBackground)
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MacDS.Radius.standard - 2)
                .stroke(MacDS.Color.border.opacity(0.5), lineWidth: 0.5)
        )
    }

    private var lastUpdatedLabel: some View {
        Group {
            if let lastUpdated, !isLoading {
                Text("Updated \(lastUpdated.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(MacDS.Color.textSecondary.opacity(0.5))
                    .padding(.trailing, DesignSpacing.spacing2)
                    .padding(.bottom, DesignSpacing.spacing1)
            }
        }
    }

    private var chartAccessibilityValue: String {
        guard let bucket = selectedBucket else { return "" }
        return "\(bucket.focusMinutes) minutes focus, \(bucket.xpEarned) XP"
    }

    private var targetLegend: some View {
        HStack(spacing: DesignSpacing.spacing6) {
            legendItem(
                color: MacDS.Color.accentTeal.opacity(0.85),
                dashed: false,
                label: "Target"
            )
            legendItem(
                color: MacDS.Color.accentTealLight,
                dashed: true,
                label: "Stretch"
            )
        }
        .font(.caption2)
        .foregroundStyle(MacDS.Color.textSecondary)
    }

    private func legendItem(color: Color, dashed: Bool, label: String) -> some View {
        HStack(spacing: DesignSpacing.spacing2) {
            RoundedRectangle(cornerRadius: 1)
                .stroke(color, style: StrokeStyle(lineWidth: 1.5, dash: dashed ? [4, 3] : []))
                .frame(width: 20, height: 2)
            Text(label)
        }
    }

    @ViewBuilder
    private func xAxisLabel(for date: Date, period: ProfileChartPeriod) -> some View {
        switch period {
        case .week:
            VStack(spacing: 0) {
                Text(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(MacDS.Color.textPrimary)
                Text("\(calendar.component(.day, from: date))")
                    .font(.caption2)
                    .foregroundStyle(MacDS.Color.textSecondary.opacity(0.7))
            }
        case .month:
            Text(ProfileChartAxisLabels.monthAxisLabel(for: date, calendar: calendar))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(MacDS.Color.textSecondary)
        case .year:
            EmptyView()
        }
    }
}

#if DEBUG
@available(macOS 14.0, *)
private enum ProfileFocusChartPreviewData {
    static func buckets(for period: ProfileChartPeriod, calendar: Calendar = .current) -> [FocusHoursChartBucket] {
        let now = Date()
        let weekStart = ProfileChartNavigation.currentWeekStart(now: now, calendar: calendar)
        let monthStart = ProfileChartNavigation.currentMonthStart(now: now, calendar: calendar)
        let yearStart = ProfileChartNavigation.currentYearStart(now: now, calendar: calendar)
        let reference = ProfileChartNavigation.chartReferenceDate(
            period: period,
            weekStart: weekStart,
            monthStart: monthStart,
            yearStart: yearStart,
            calendar: calendar
        )
        return FocusHoursChartBucketBuilder.build(
            window: period.statsDashboardWindow,
            referenceNow: reference,
            calendar: calendar,
            completedSessions: []
        )
    }
}

@available(macOS 14.0, *)
#Preview("Week") {
    ProfileFocusChartView(
        period: .week,
        buckets: ProfileFocusChartPreviewData.buckets(for: .week),
        isLoading: false,
        focusHackerDailyTargetMinutes: ProfileChartTargets.dailyMinutes(
            fromWeekly: ProfileDashboardMetrics.defaultWeeklyMinutesTarget
        ),
        personalDailyTargetMinutes: ProfileChartTargets.dailyMinutes(fromWeekly: 600),
        lastUpdated: Date(),
        selectedBucket: .constant(nil)
    )
    .frame(width: 480, height: 280)
    .padding()
}

@available(macOS 14.0, *)
#Preview("Month") {
    ProfileFocusChartView(
        period: .month,
        buckets: ProfileFocusChartPreviewData.buckets(for: .month),
        isLoading: false,
        focusHackerDailyTargetMinutes: ProfileChartTargets.dailyMinutes(
            fromWeekly: ProfileDashboardMetrics.defaultWeeklyMinutesTarget
        ),
        personalDailyTargetMinutes: ProfileChartTargets.dailyMinutes(fromWeekly: 600),
        lastUpdated: Date(),
        selectedBucket: .constant(nil)
    )
    .frame(width: 480, height: 280)
    .padding()
}

@available(macOS 14.0, *)
#Preview("Year") {
    ProfileFocusChartView(
        period: .year,
        buckets: ProfileFocusChartPreviewData.buckets(for: .year),
        isLoading: false,
        focusHackerDailyTargetMinutes: ProfileChartTargets.dailyMinutes(
            fromWeekly: ProfileDashboardMetrics.defaultWeeklyMinutesTarget
        ),
        personalDailyTargetMinutes: ProfileChartTargets.dailyMinutes(fromWeekly: 600),
        lastUpdated: Date(),
        selectedBucket: .constant(nil)
    )
    .frame(width: 480, height: 280)
    .padding()
}
#endif
