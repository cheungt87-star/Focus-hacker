import Foundation

struct ProfileChartYAxisPolicy {
    static let defaultDomainMaxMinutes: Double = 240
    static let defaultTickStepMinutes: Double = 60
    static let yearMinimumDomainMaxMinutes: Double = 600
    static let yearTickStepMinutes: Double = 600

    let domainMaxMinutes: Double
    let tickValuesMinutes: [Double]

    func formatLabel(minutes: Double) -> String {
        let rounded = Int(minutes.rounded())
        if rounded == 0 {
            return "0h"
        }
        if rounded % 60 == 0 {
            return "\(rounded / 60)h"
        }
        let hours = Double(rounded) / 60.0
        return String(format: "%.1fh", hours)
    }
}

enum ProfileChartYAxisPolicyBuilder {
    static func make(
        period: ProfileChartPeriod,
        dataMaxMinutes: Int,
        targetMinutes: [Int]
    ) -> ProfileChartYAxisPolicy {
        _ = targetMinutes

        switch period {
        case .week, .month:
            return fixedDailyPolicy()
        case .year:
            return yearPolicy(dataMaxMinutes: dataMaxMinutes)
        }
    }

    private static func fixedDailyPolicy() -> ProfileChartYAxisPolicy {
        var ticks: [Double] = []
        var value = 0.0
        while value <= ProfileChartYAxisPolicy.defaultDomainMaxMinutes + 0.001 {
            ticks.append(value)
            value += ProfileChartYAxisPolicy.defaultTickStepMinutes
        }
        return ProfileChartYAxisPolicy(
            domainMaxMinutes: ProfileChartYAxisPolicy.defaultDomainMaxMinutes,
            tickValuesMinutes: ticks
        )
    }

    private static func yearPolicy(dataMaxMinutes: Int) -> ProfileChartYAxisPolicy {
        let step = ProfileChartYAxisPolicy.yearTickStepMinutes
        let domainMax = yearDomainMax(dataMaxMinutes: dataMaxMinutes, step: step)
        var ticks: [Double] = []
        var value = 0.0
        while value <= domainMax + 0.001 {
            ticks.append(value)
            value += step
        }
        return ProfileChartYAxisPolicy(domainMaxMinutes: domainMax, tickValuesMinutes: ticks)
    }

    private static func yearDomainMax(dataMaxMinutes: Int, step: Double) -> Double {
        let minimum = ProfileChartYAxisPolicy.yearMinimumDomainMaxMinutes
        let needed = max(minimum, Double(max(0, dataMaxMinutes)))
        return ceil(needed / step) * step
    }
}
