import Foundation

struct FocusSessionPreset: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let focusMinutes: Int
    let breakMinutes: Int
    let roundsPerSession: Int
    let isRecommended: Bool

    var timerConfiguration: TimerConfiguration {
        TimerConfiguration(
            focusDurationSeconds: focusMinutes * 60,
            shortRestDurationSeconds: breakMinutes * 60,
            longRestDurationSeconds: 0,
            roundsPerSession: roundsPerSession,
            cyclesPerSession: 1
        )
    }

    var descriptionLine: String {
        "\(focusMinutes) min focus / \(breakMinutes) min break × \(roundsPerSession) cycles"
    }

    /// Carousel subtitle (middle-dot separators, matches focus session card mock).
    var carouselDescriptionLine: String {
        "\(focusMinutes) min · \(breakMinutes) min break · \(roundsPerSession) cycles"
    }

    var totalSessionMinutes: Int {
        timerConfiguration.approximateWallClockMinutes
    }

    var totalFocusMinutes: Int {
        timerConfiguration.plannedTotalFocusSeconds / 60
    }
}

enum FocusSessionPresets {
    /// Carousel slot for in-popover custom session configuration (not a fixed timer preset).
    static let createCustomCarouselID = "create-custom"

    static let classic = FocusSessionPreset(
        id: "classic",
        name: "Classic",
        focusMinutes: 25,
        breakMinutes: 5,
        roundsPerSession: 4,
        isRecommended: true
    )

    static let intense = FocusSessionPreset(
        id: "intense",
        name: "Intense",
        focusMinutes: 40,
        breakMinutes: 10,
        roundsPerSession: 3,
        isRecommended: false
    )

    static let expert = FocusSessionPreset(
        id: "expert",
        name: "Expert",
        focusMinutes: 50,
        breakMinutes: 10,
        roundsPerSession: 3,
        isRecommended: false
    )

    static let all: [FocusSessionPreset] = [classic, intense, expert]

    /// Preset carousel order in the menu bar popover (includes Create Custom).
    static let popoverCarouselPresetIDs: [String] = [
        classic.id,
        intense.id,
        expert.id,
        createCustomCarouselID
    ]

    static let defaultSelection: FocusSessionPreset = classic

    static func preset(id: String) -> FocusSessionPreset? {
        all.first { $0.id == id }
    }

    static func isCreateCustomCarouselSelection(_ presetID: String?) -> Bool {
        presetID == createCustomCarouselID
    }
}
