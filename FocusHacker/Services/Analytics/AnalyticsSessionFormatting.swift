import Foundation

enum AnalyticsSessionFormatting {
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_GB_POSIX")
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE dd/MM/yy"
        formatter.locale = Locale(identifier: "en_GB_POSIX")
        return formatter
    }()

    static func tableDateLabel(for date: Date, calendar: Calendar = .current) -> String {
        dateFormatter.calendar = calendar
        dateFormatter.timeZone = calendar.timeZone
        return dateFormatter.string(from: date).uppercased()
    }

    static func tableTimeLabel(for date: Date?, calendar: Calendar = .current) -> String {
        guard let date else { return "—" }
        timeFormatter.calendar = calendar
        timeFormatter.timeZone = calendar.timeZone
        return timeFormatter.string(from: date)
    }

    static func focusDuration(minutes: Int) -> String {
        ProfileChartAxisLabels.tooltipFocusDuration(minutes: minutes)
    }

    static func completionPercentLabel(_ percent: Int) -> String {
        "\(percent)%"
    }
}
