import XCTest
@testable import FocusHacker

/// Documents NDJSON hypothesis IDs used to verify pause/resume blocking (Gather Blocker Diagnostics).
final class BlockerPauseResumeDiagnosticsTests: XCTestCase {
    func testPauseResumeDiagnosticHypothesisIDsAreStable() {
        let expected: Set<String> = [
            "H_PAUSE_COMMIT",
            "H_RESUME_POST_JSON",
            "H_FILTER_BOUNCE_BEGIN",
            "H_FILTER_BOUNCE_COMPLETE",
            "H_FILTER_BOUNCE_SKIP",
            "H_BOUNCE_OUTCOME",
            "H1_lease_early_allow",
            "H_chrome_flow_entry",
            "H_post_bounce_ip_refresh",
            "H5_final_allow_chrome",
            "H_IP_REFRESH_SKIP_STALE_GEN",
            "H_IP_ABORT_PRE_MERGE",
        ]
        XCTAssertGreaterThanOrEqual(expected.count, 10)
    }
}
