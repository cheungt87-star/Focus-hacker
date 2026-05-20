import Foundation

enum AppBlockingConfiguration {
    private static let userDefaultsKey = "blocker.useAppLaunchTermination"

    /// When true, blocked native apps are terminated on launch during focus intervals.
    static var isEnabled: Bool {
        if UserDefaults.standard.object(forKey: userDefaultsKey) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: userDefaultsKey)
    }

    static func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: userDefaultsKey)
    }
}
