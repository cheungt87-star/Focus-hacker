import Foundation

struct ProfileChartYAxisPolicy {
    let domainMaxMinutes: Double
    let tickValuesMinutes: [Double]
    let usesHourLabels: Bool

    func formatLabel(minutes: Double) -> String {
        let rounded = Int(minutes.rounded())
        if usesHourLabels, rounded >= 60, rounded % 60 == 0 {
            let hours = rounded / 60
            return "\(hours)h"
        }
        return "\(rounded)"
    }
}

enum ProfileChartYAxisPolicyBuilder {
    static func make(
        period: ProfileChartPeriod,
        dataMaxMinutes: Int,
        targetMinutes: [Int]
    ) -> ProfileChartYAxisPolicy {
        let step = tickStepMinutes(for: period)
        let ceiling = Double(max(dataMaxMinutes, targetMinutes.max() ?? 0, 1))
        let padded = ceiling * 1.15
        let domainMax = max(step, ceil(padded / step) * step)
        var ticks: [Double] = []
        var value = 0.0
        while value <= domainMax + 0.001 {
            ticks.append(value)
            value += step
        }
        return ProfileChartYAxisPolicy(
            domainMaxMinutes: domainMax,
            tickValuesMinutes: ticks,
            usesHourLabels: period != .week
        )
    }

    private static func tickStepMinutes(for period: ProfileChartPeriod) -> Double {
        switch period {
        case .week: return 30
        case .month: return 60
        case .sixMonths, .year: return 120
        }
    }

    private static func ceil(_ value: Double) -> Double {
        Foundation.ceil(value)
    }
}
