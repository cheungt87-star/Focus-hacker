import Foundation

enum ProfileChartAxisLabels {
    /// X-axis ticks for calendar month charts: day 1, every 5 days, and last day of month.
    static func monthFiveDayLabelDates(
        from buckets: [FocusHoursChartBucket],
        calendar: Calendar = .current
    ) -> [Date] {
        guard let monthStart = buckets.first?.periodStart,
              let dayRange = calendar.range(of: .day, in: .month, for: monthStart)
        else {
            return []
        }

        let lastDay = dayRange.count
        var labelDays = [1]
        var day = 6
        while day <= lastDay {
            labelDays.append(day)
            day += 5
        }
        if labelDays.last != lastDay {
            labelDays.append(lastDay)
        }

        return labelDays.compactMap { labelDay -> Date? in
            var components = calendar.dateComponents([.year, .month], from: monthStart)
            components.day = labelDay
            guard let date = calendar.date(from: components) else { return nil }
            return calendar.startOfDay(for: date)
        }
    }

    static func xAxisDates(
        period: ProfileChartPeriod,
        buckets: [FocusHoursChartBucket],
        calendar: Calendar = .current
    ) -> [Date] {
        switch period {
        case .week, .year:
            return []
        case .month:
            return monthFiveDayLabelDates(from: buckets, calendar: calendar)
        }
    }

    static func ordinalSuffix(for day: Int) -> String {
        let ones = day % 10
        let tens = (day % 100) / 10
        if tens == 1 {
            return "th"
        }
        switch ones {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
        }
    }

    static func monthAxisLabel(for date: Date, calendar: Calendar = .current) -> String {
        let day = calendar.component(.day, from: date)
        return "\(day)\(ordinalSuffix(for: day))"
    }

    static func tooltipDateLabel(for date: Date, period: ProfileChartPeriod, calendar: Calendar = .current) -> String {
        switch period {
        case .week:
            return date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        case .month:
            return date.formatted(.dateTime.day().month(.abbreviated).year())
        case .year:
            return date.formatted(.dateTime.month(.wide).year())
        }
    }

    static func tooltipFocusDuration(minutes: Int) -> String {
        if minutes == 0 {
            return "0h"
        }
        let hours = minutes / 60
        let remainder = minutes % 60
        if hours == 0 {
            return "\(remainder)m"
        }
        if remainder == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(remainder)m"
    }
}
