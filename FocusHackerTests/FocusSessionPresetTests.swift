@testable import FocusHacker
import XCTest

final class FocusSessionPresetTests: XCTestCase {
    func testClassicPresetTotals() {
        let preset = FocusSessionPresets.classic
        XCTAssertEqual(preset.totalSessionMinutes, 115)
        XCTAssertEqual(preset.totalFocusMinutes, 100)
        XCTAssertTrue(preset.isRecommended)
    }

    func testIntensePresetTotals() {
        let preset = FocusSessionPresets.intense
        XCTAssertEqual(preset.totalSessionMinutes, 140)
        XCTAssertEqual(preset.totalFocusMinutes, 120)
        XCTAssertFalse(preset.isRecommended)
    }

    func testExpertPresetTotals() {
        let preset = FocusSessionPresets.expert
        XCTAssertEqual(preset.totalSessionMinutes, 170)
        XCTAssertEqual(preset.totalFocusMinutes, 150)
        XCTAssertFalse(preset.isRecommended)
        XCTAssertEqual(preset.carouselDescriptionLine, "50 min · 10 min break · 3 cycles")
    }

    func testPresetLookupByID() {
        XCTAssertEqual(FocusSessionPresets.preset(id: "intense"), FocusSessionPresets.intense)
        XCTAssertNil(FocusSessionPresets.preset(id: "unknown"))
        XCTAssertTrue(FocusSessionPresets.isCreateCustomCarouselSelection(FocusSessionPresets.createCustomCarouselID))
        XCTAssertFalse(FocusSessionPresets.isCreateCustomCarouselSelection("classic"))
        XCTAssertEqual(FocusSessionPresets.popoverCarouselPresetIDs.count, 4)
    }
}
