import SwiftUI

enum AppearancePreference: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var symbolName: String {
        switch self {
        case .system: return "display"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    func resolvedColorScheme(fallback: ColorScheme) -> ColorScheme {
        preferredColorScheme ?? fallback
    }

    func effectiveModeLabel(resolvedColorScheme: ColorScheme) -> String {
        switch self {
        case .system:
            return "System (\(resolvedColorScheme == .dark ? "Dark" : "Light"))"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
}
