import Foundation

enum ProfileFocusChartMockData {
    static func buckets(
        for period: ProfileChartPeriod,
        endingAt referenceNow: Date = Date(),
        calendar: Calendar = .current
    ) -> [FocusHoursChartBucket] {
        let dayCount = period.rollingDayCount
        let todayStart = calendar.startOfDay(for: referenceNow)
        guard dayCount > 0 else { return [] }

        return (0..<dayCount).compactMap { index -> FocusHoursChartBucket? in
            let daysFromStart = index - (dayCount - 1)
            guard let dayStart = calendar.date(byAdding: .day, value: daysFromStart, to: todayStart)
            else {
                return nil
            }
            let focusMinutes = mockFocusMinutes(for: dayStart, calendar: calendar)
            let weekday = dayStart.formatted(.dateTime.weekday(.abbreviated))
            let dayNumber = calendar.component(.day, from: dayStart)
            return FocusHoursChartBucket(
                id: "mock-\(dayStart.timeIntervalSince1970)",
                label: "\(weekday) \(dayNumber)",
                focusMinutes: focusMinutes,
                periodStart: dayStart
            )
        }
    }

    private static func mockFocusMinutes(for dayStart: Date, calendar: Calendar) -> Int {
        let weekday = calendar.component(.weekday, from: dayStart)
        let dayOfMonth = calendar.component(.day, from: dayStart)
        let isWeekend = weekday == 1 || weekday == 7
        let seed = (dayOfMonth * 17 + weekday * 31) % 100

        if seed < 8 {
            return 0
        }

        let baseHours: Double
        if isWeekend {
            baseHours = 0.5 + Double(seed % 20) / 20.0
        } else {
            baseHours = 1.0 + Double(seed % 50) / 20.0
        }
        return Int((baseHours * 60).rounded())
    }
}
