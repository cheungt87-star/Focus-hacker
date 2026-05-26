import AppKit
import Foundation

enum AutomationPermissionState: Equatable {
    case unknown
    case granted
    case denied
}

struct BrowserTabRef: Equatable {
    let windowIndex: Int
    let tabIndex: Int
    let urlString: String
}

enum BrowserAppleScriptRunner {
    private static let fieldSeparator = "\u{1F}"
    private static let recordSeparator = "\u{1E}"

    static func escapeForAppleScriptLiteral(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    /// Window-count probe — always `tell application` (launches browser if needed) so TCC registers the target.
    /// User-initiated permission flows only; passive checks use `runListTabs` when the browser is already running.
    static func runAutomationRegistrationProbe(applicationName: String) -> Result<String, Error> {
        let scriptSource = applicationName == "Google Chrome"
            ? chromeRegistrationProbeScript()
            : safariRegistrationProbeScript()
        return runReturningString(scriptSource).map { raw in
            raw.hasPrefix("registered:") ? raw : "registered:unknown"
        }
    }

    private static func safariRegistrationProbeScript() -> String {
        """
        tell application "Safari"
            set n to count of windows
            return "registered:" & (n as text)
        end tell
        """
    }

    private static func chromeRegistrationProbeScript() -> String {
        """
        tell application "Google Chrome"
            set n to count of windows
            return "registered:" & (n as text)
        end tell
        """
    }

    static func runListTabs(applicationName: String) -> Result<[BrowserTabRef], Error> {
        let scriptSource = applicationName == "Google Chrome" ? chromeListTabsScript() : safariListTabsScript()
        return runReturningString(scriptSource).map(parseTabList)
    }

    private static func safariListTabsScript() -> String {
        """
        tell application "Safari"
            if not running then return ""
            set _out to ""
            repeat with wi from 1 to (count of windows)
                try
                    repeat with ti from 1 to (count of tabs of window wi)
                        try
                            set u to URL of tab ti of window wi as text
                        on error
                            set u to ""
                        end try
                        set _out to _out & (wi as text) & "\(fieldSeparator)" & (ti as text) & "\(fieldSeparator)" & u & "\(recordSeparator)"
                    end repeat
                end try
            end repeat
            return _out
        end tell
        """
    }

    private static func chromeListTabsScript() -> String {
        """
        tell application "Google Chrome"
            if not running then return ""
            set _out to ""
            repeat with wi from 1 to (count of windows)
                try
                    repeat with ti from 1 to (count of tabs of window wi)
                        try
                            set u to URL of tab ti of window wi as text
                        on error
                            set u to ""
                        end try
                        set _out to _out & (wi as text) & "\(fieldSeparator)" & (ti as text) & "\(fieldSeparator)" & u & "\(recordSeparator)"
                    end repeat
                end try
            end repeat
            return _out
        end tell
        """
    }

    static func runRedirectTab(
        applicationName: String,
        windowIndex: Int,
        tabIndex: Int,
        to urlString: String
    ) -> Result<Void, Error> {
        let scriptSource = """
        tell application "\(escapeForAppleScriptLiteral(applicationName))"
            if not running then return "ok"
            try
                set URL of tab \(tabIndex) of window \(windowIndex) to "\(escapeForAppleScriptLiteral(urlString))"
            end try
            return "ok"
        end tell
        """
        return runReturningString(scriptSource).map { _ in () }
    }

    /// `errAEEventNotPermitted` when Automation permission was not granted.
    static let appleEventNotPermittedCode = -1743

    static func permissionState(for error: Error) -> AutomationPermissionState {
        let ns = error as NSError
        if ns.code == appleEventNotPermittedCode {
            return .denied
        }
        return .unknown
    }

    private static func runReturningString(_ source: String) -> Result<String, Error> {
        var errorInfo: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            return .failure(ScriptError.compilationFailed)
        }
        let output = script.executeAndReturnError(&errorInfo)
        if let errorInfo {
            let code = (errorInfo[NSAppleScript.errorNumber] as? Int) ?? -1
            return .failure(NSError(domain: "com.focushacker.applescript", code: code, userInfo: errorInfo as? [String: Any]))
        }
        return .success(output.stringValue ?? "")
    }

    private static func parseTabList(_ raw: String) -> [BrowserTabRef] {
        guard !raw.isEmpty else {
            return []
        }
        var tabs: [BrowserTabRef] = []
        for record in raw.split(separator: Character(recordSeparator), omittingEmptySubsequences: true) {
            let parts = record.split(separator: Character(fieldSeparator), omittingEmptySubsequences: false)
            guard parts.count >= 3,
                  let windowIndex = Int(parts[0]),
                  let tabIndex = Int(parts[1]) else {
                continue
            }
            let urlString = parts.dropFirst(2).joined(separator: String(fieldSeparator))
            guard !urlString.isEmpty else {
                continue
            }
            tabs.append(BrowserTabRef(windowIndex: windowIndex, tabIndex: tabIndex, urlString: urlString))
        }
        return tabs
    }

    enum ScriptError: Error {
        case compilationFailed
    }
}
