import CoreGraphics
import XCTest
@testable import FocusHacker

final class AppWindowPreviewCaptureTests: XCTestCase {
    func testSelectFrontmostWindowSkipsNonMatchingPID() {
        let windows: [[String: Any]] = [
            windowInfo(pid: 100, windowID: 1, layer: 0, bounds: CGRect(x: 0, y: 0, width: 800, height: 600)),
            windowInfo(pid: 200, windowID: 2, layer: 0, bounds: CGRect(x: 0, y: 0, width: 400, height: 300)),
        ]

        let selected = AppWindowPreviewCapture.frontmostWindow(from: windows, ownerPID: 200)
        XCTAssertEqual(selected?.windowID, 2)
    }

    func testSelectFrontmostWindowPrefersFirstOnScreenMatch() {
        let windows: [[String: Any]] = [
            windowInfo(pid: 42, windowID: 10, layer: 0, bounds: CGRect(x: 0, y: 0, width: 1200, height: 800)),
            windowInfo(pid: 42, windowID: 11, layer: 0, bounds: CGRect(x: 0, y: 0, width: 400, height: 300)),
        ]

        let selected = AppWindowPreviewCapture.frontmostWindow(from: windows, ownerPID: 42)
        XCTAssertEqual(selected?.windowID, 10)
    }

    func testSelectFrontmostWindowSkipsMenuBarLayer() {
        let windows: [[String: Any]] = [
            windowInfo(pid: 42, windowID: 10, layer: 25, bounds: CGRect(x: 0, y: 0, width: 1200, height: 24)),
            windowInfo(pid: 42, windowID: 11, layer: 0, bounds: CGRect(x: 0, y: 0, width: 400, height: 300)),
        ]

        let selected = AppWindowPreviewCapture.frontmostWindow(from: windows, ownerPID: 42)
        XCTAssertEqual(selected?.windowID, 11)
    }

    func testSelectFrontmostWindowSkipsZeroSizeBounds() {
        let windows: [[String: Any]] = [
            windowInfo(pid: 42, windowID: 10, layer: 0, bounds: CGRect(x: 0, y: 0, width: 0, height: 0)),
            windowInfo(pid: 42, windowID: 11, layer: 0, bounds: CGRect(x: 0, y: 0, width: 400, height: 300)),
        ]

        let selected = AppWindowPreviewCapture.frontmostWindow(from: windows, ownerPID: 42)
        XCTAssertEqual(selected?.windowID, 11)
    }

    func testBoundsFromWindowInfoParsesNSDictionaryShape() {
        let info: [String: Any] = [
            kCGWindowBounds as String: [
                "X": 12,
                "Y": 34,
                "Width": 640,
                "Height": 480,
            ],
        ]

        let bounds = AppWindowPreviewCapture.boundsFromWindowInfo(info)
        XCTAssertEqual(bounds, CGRect(x: 12, y: 34, width: 640, height: 480))
    }

    func testIsApplicationBundleURL() {
        let appURL = URL(fileURLWithPath: "/Applications/Safari.app")
        let contentsURL = URL(fileURLWithPath: "/Applications/Safari.app/Contents")
        XCTAssertTrue(AppWindowPreviewCapture.isApplicationBundleURL(appURL))
        XCTAssertFalse(AppWindowPreviewCapture.isApplicationBundleURL(contentsURL))
    }

    @MainActor
    func testPreviewForNonRunningAppReturnsIconOnly() {
        let url = URL(fileURLWithPath: "/Applications/NonexistentFocusHackerTestApp.app")
        let preview = AppWindowPreviewCapture.preview(forApplicationURL: url)
        XCTAssertFalse(preview.isRunning)
        XCTAssertNil(preview.screenshot)
        XCTAssertGreaterThan(preview.icon.size.width, 0)
    }

    private func windowInfo(
        pid: pid_t,
        windowID: CGWindowID,
        layer: Int,
        bounds: CGRect
    ) -> [String: Any] {
        [
            kCGWindowOwnerPID as String: pid,
            kCGWindowNumber as String: windowID,
            kCGWindowLayer as String: layer,
            kCGWindowAlpha as String: 1.0,
            kCGWindowBounds as String: [
                "X": bounds.origin.x,
                "Y": bounds.origin.y,
                "Width": bounds.size.width,
                "Height": bounds.size.height,
            ],
        ]
    }
}

final class AppBundleIdentifierPickerTests: XCTestCase {
    func testApplicationBundleURLValidation() {
        XCTAssertTrue(
            AppWindowPreviewCapture.isApplicationBundleURL(
                URL(fileURLWithPath: "/Applications/Claude.app")
            )
        )
        XCTAssertFalse(
            AppWindowPreviewCapture.isApplicationBundleURL(
                URL(fileURLWithPath: "/Applications/Claude.app/Contents/MacOS/Claude")
            )
        )
    }
}
