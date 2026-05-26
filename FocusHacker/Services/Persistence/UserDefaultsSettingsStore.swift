import Foundation

struct UserDefaultsSettingsStore {
    private enum Key {
        static let focusDurationMinutes = "settings.timer.focusDurationMinutes"
        static let shortRestDurationMinutes = "settings.timer.shortRestDurationMinutes"
        static let longRestDurationMinutes = "settings.timer.longRestDurationMinutes"
        static let focusDurationSeconds = "settings.timer.focusDurationSeconds"
        static let shortRestDurationSeconds = "settings.timer.shortRestDurationSeconds"
        static let longRestDurationSeconds = "settings.timer.longRestDurationSeconds"
        static let roundsPerSession = "settings.timer.roundsPerSession"
        static let cyclesPerSession = "settings.timer.cyclesPerSession"
        static let lastSelectedFocusPresetID = "settings.timer.lastSelectedFocusPresetID"
        static let selectedSoundPackIdentifier = "settings.audio.selectedSoundPackIdentifier"
        static let selectedVoiceOption = "settings.audio.selectedVoiceOption"
        static let isAudioMuted = "settings.audio.isMuted"
        static let blockedDomains = BlockerAppGroup.StandardUserDefaultsKey.blockedDomains
        static let blockedBundleIdentifiers = BlockerAppGroup.StandardUserDefaultsKey.blockedBundleIdentifiers
        static let selectedAppShellSection = "settings.appShell.selectedSection"
        static let appearancePreference = "settings.appShell.appearancePreference"
        static let blockerOnboardingPresented = "onboarding.blocker.didPresentExplanation"

        /// When set, authoritative; when unset, onboarding completion is inferred from blocker onboarding for migration.
        static let hasCompletedFullOnboarding = "onboarding.didCompleteGuidedFlow"
        /// Cache only — refreshed when the user responds to an authorization prompt.
        static let lastNotificationAuthorizationGranted = "onboarding.cache.notificationsGranted"
        static let notificationsAuthorizationPromptRecorded = "onboarding.cache.notificationsPromptRecorded"

        /// US-028: read-through only — mirrored from verified StoreKit subscription window for cold/offline UX when reads fail.
        static let cachedTrialAccessExpiresAt = "focushacker.trialAccess.cache.expiryDate"
        /// US-028: first observed subscription (`purchaseDate`), read-through cache mirrored from verified StoreKit.
        static let trialStartPurchaseDateCache = "focushacker.trialStartDate"
        static let weeklyXPGoalXP = "settings.gamification.weeklyXPGoalXP"
        static let personalWeeklyMinutesTarget = "settings.gamification.personalWeeklyMinutesTarget"
        static let personalTargetLastModified = "settings.gamification.personalTargetLastModified"
        static let gamificationXPBackfillCompleted = "settings.gamification.xpBackfillCompleted"
        static let lifetimeXPResetAt = "settings.gamification.lifetimeXPResetAt"
        static let profileDisplayName = "settings.profile.displayName"
    }

    static let personalWeeklyMinutesMin = 100
    static let personalWeeklyMinutesMax = 2_000
    static let personalWeeklyMinutesDefault = 600

    static let profileDisplayNameMaxLength = 32
    static let profileDisplayNameDefault = "You"

    var cachedTrialAccessExpiryDateSnapshot: Date? {
        get { userDefaults.object(forKey: Key.cachedTrialAccessExpiresAt) as? Date }
        nonmutating set {
            if let newValue {
                userDefaults.set(newValue, forKey: Key.cachedTrialAccessExpiresAt)
            } else {
                userDefaults.removeObject(forKey: Key.cachedTrialAccessExpiresAt)
            }
        }
    }

    /// First verified subscription (`com.focushacker.intro`) `purchaseDate` mirror for Settings copy.
    var trialPurchaseStartDateCacheSnapshot: Date? {
        get { userDefaults.object(forKey: Key.trialStartPurchaseDateCache) as? Date }
        nonmutating set {
            if let newValue {
                userDefaults.set(newValue, forKey: Key.trialStartPurchaseDateCache)
            } else {
                userDefaults.removeObject(forKey: Key.trialStartPurchaseDateCache)
            }
        }
    }

    private let userDefaults: UserDefaults
    private let suiteDefaults: UserDefaults?

    /// Pass `nil` for `appGroupSuiteName` in unit tests when App Group syncing should be skipped.
    init(userDefaults: UserDefaults = .standard, appGroupSuiteName: String? = BlockerAppGroup.identifier) {
        self.userDefaults = userDefaults
        self.suiteDefaults = appGroupSuiteName.flatMap { UserDefaults(suiteName: $0) }
        registerDefaultsIfNeeded()
        migrateLegacyMinuteDurationsIfNeeded()
        mirrorBlocklistIntoSuite()
    }

    var didPresentBlockerOnboarding: Bool {
        get { userDefaults.bool(forKey: Key.blockerOnboardingPresented) }
        nonmutating set { userDefaults.set(newValue, forKey: Key.blockerOnboardingPresented) }
    }

    /// First-launch onboarding (US-024). Unset defaults to migrating users who dismissed blocker onboarding.
    var hasCompletedFullOnboarding: Bool {
        get {
            if userDefaults.object(forKey: Key.hasCompletedFullOnboarding) != nil {
                return userDefaults.bool(forKey: Key.hasCompletedFullOnboarding)
            }
            return userDefaults.bool(forKey: Key.blockerOnboardingPresented)
        }
        nonmutating set { userDefaults.set(newValue, forKey: Key.hasCompletedFullOnboarding) }
    }

    var lastNotificationAuthorizationGrantedSnapshot: Bool {
        get { userDefaults.bool(forKey: Key.lastNotificationAuthorizationGranted) }
        nonmutating set { userDefaults.set(newValue, forKey: Key.lastNotificationAuthorizationGranted) }
    }

    /// True after we attempted to capture notification permission state during onboarding/settings.
    var notificationAuthorizationPromptWasRecorded: Bool {
        get { userDefaults.bool(forKey: Key.notificationsAuthorizationPromptRecorded) }
        nonmutating set { userDefaults.set(newValue, forKey: Key.notificationsAuthorizationPromptRecorded) }
    }

    var focusDurationSeconds: Int {
        get {
            durationSeconds(
                for: Key.focusDurationSeconds,
                legacyMinutesKey: Key.focusDurationMinutes,
                minutesRange: 1...120,
                defaultMinutes: 25
            )
        }
        nonmutating set { userDefaults.set(Self.clampDurationSeconds(newValue, maxMinutes: 120), forKey: Key.focusDurationSeconds) }
    }

    var shortRestDurationSeconds: Int {
        get {
            durationSeconds(
                for: Key.shortRestDurationSeconds,
                legacyMinutesKey: Key.shortRestDurationMinutes,
                minutesRange: 1...30,
                defaultMinutes: 5
            )
        }
        nonmutating set { userDefaults.set(Self.clampDurationSeconds(newValue, maxMinutes: 30), forKey: Key.shortRestDurationSeconds) }
    }

    var longRestDurationSeconds: Int {
        get {
            durationSeconds(
                for: Key.longRestDurationSeconds,
                legacyMinutesKey: Key.longRestDurationMinutes,
                minutesRange: 1...60,
                defaultMinutes: 15
            )
        }
        nonmutating set { userDefaults.set(Self.clampDurationSeconds(newValue, maxMinutes: 60), forKey: Key.longRestDurationSeconds) }
    }

    var roundsPerSession: Int {
        get { Self.clamp(userDefaults.integer(forKey: Key.roundsPerSession), within: 1...99) }
        nonmutating set { userDefaults.set(Self.clamp(newValue, within: 1...99), forKey: Key.roundsPerSession) }
    }

    var cyclesPerSession: Int {
        get { Self.clamp(userDefaults.integer(forKey: Key.cyclesPerSession), within: 1...10) }
        nonmutating set { userDefaults.set(Self.clamp(newValue, within: 1...10), forKey: Key.cyclesPerSession) }
    }

    var lastSelectedFocusPresetID: String? {
        get { userDefaults.string(forKey: Key.lastSelectedFocusPresetID) }
        nonmutating set {
            if let newValue {
                userDefaults.set(newValue, forKey: Key.lastSelectedFocusPresetID)
            } else {
                userDefaults.removeObject(forKey: Key.lastSelectedFocusPresetID)
            }
        }
    }

    var selectedSoundPackIdentifier: String {
        get { userDefaults.string(forKey: Key.selectedSoundPackIdentifier) ?? "voice-prompts" }
        nonmutating set { userDefaults.set(newValue, forKey: Key.selectedSoundPackIdentifier) }
    }

    var selectedVoiceOption: String {
        get { userDefaults.string(forKey: Key.selectedVoiceOption) ?? VoiceOption.defaultSelection.rawValue }
        nonmutating set { userDefaults.set(newValue, forKey: Key.selectedVoiceOption) }
    }

    var isAudioMuted: Bool {
        get { userDefaults.bool(forKey: Key.isAudioMuted) }
        nonmutating set { userDefaults.set(newValue, forKey: Key.isAudioMuted) }
    }

    var blockedDomains: [String] {
        get { userDefaults.stringArray(forKey: Key.blockedDomains) ?? [] }
        nonmutating set {
            userDefaults.set(newValue, forKey: Key.blockedDomains)
            mirrorBlocklistIntoSuite()
        }
    }

    var blockedBundleIdentifiers: [String] {
        get { userDefaults.stringArray(forKey: Key.blockedBundleIdentifiers) ?? [] }
        nonmutating set {
            userDefaults.set(newValue, forKey: Key.blockedBundleIdentifiers)
            mirrorBlocklistIntoSuite()
        }
    }

    var selectedAppShellSection: String {
        get { userDefaults.string(forKey: Key.selectedAppShellSection) ?? "history" }
        nonmutating set { userDefaults.set(newValue, forKey: Key.selectedAppShellSection) }
    }

    var appearancePreference: AppearancePreference {
        get {
            guard let raw = userDefaults.string(forKey: Key.appearancePreference),
                  let preference = AppearancePreference(rawValue: raw) else {
                return .system
            }
            return preference
        }
        nonmutating set { userDefaults.set(newValue.rawValue, forKey: Key.appearancePreference) }
    }

    /// Local display name for My profile (trimmed, max 32 characters).
    var profileDisplayName: String {
        get {
            let raw = userDefaults.string(forKey: Key.profileDisplayName) ?? Self.profileDisplayNameDefault
            return Self.sanitizeProfileDisplayName(raw)
        }
        nonmutating set {
            userDefaults.set(Self.sanitizeProfileDisplayName(newValue), forKey: Key.profileDisplayName)
        }
    }

    static func sanitizeProfileDisplayName(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return profileDisplayNameDefault
        }
        return String(trimmed.prefix(profileDisplayNameMaxLength))
    }

    /// Personal weekly focus minutes target (GAMIFICATION_SPEC). Clamped 100…2000; default 600.
    var personalWeeklyMinutesTarget: Int {
        get {
            let raw = userDefaults.integer(forKey: Key.personalWeeklyMinutesTarget)
            if userDefaults.object(forKey: Key.personalWeeklyMinutesTarget) == nil {
                return Self.personalWeeklyMinutesDefault
            }
            return Self.clampPersonalWeeklyMinutes(raw)
        }
        nonmutating set {
            let clamped = Self.clampPersonalWeeklyMinutes(newValue)
            let previous = personalWeeklyMinutesTarget
            userDefaults.set(clamped, forKey: Key.personalWeeklyMinutesTarget)
            if clamped != previous {
                personalTargetLastModified = Date()
            }
        }
    }

    var personalTargetLastModified: Date? {
        get { userDefaults.object(forKey: Key.personalTargetLastModified) as? Date }
        nonmutating set {
            if let newValue {
                userDefaults.set(newValue, forKey: Key.personalTargetLastModified)
            } else {
                userDefaults.removeObject(forKey: Key.personalTargetLastModified)
            }
        }
    }

    var gamificationXPBackfillCompleted: Bool {
        get { userDefaults.bool(forKey: Key.gamificationXPBackfillCompleted) }
        nonmutating set { userDefaults.set(newValue, forKey: Key.gamificationXPBackfillCompleted) }
    }

    /// When set, lifetime XP sums only `XPRecord` rows created at or after this instant.
    var lifetimeXPResetAt: Date? {
        get { userDefaults.object(forKey: Key.lifetimeXPResetAt) as? Date }
        nonmutating set {
            if let newValue {
                userDefaults.set(newValue, forKey: Key.lifetimeXPResetAt)
            } else {
                userDefaults.removeObject(forKey: Key.lifetimeXPResetAt)
            }
        }
    }

    static func clampPersonalWeeklyMinutes(_ value: Int) -> Int {
        clamp(value, within: personalWeeklyMinutesMin...personalWeeklyMinutesMax)
    }

    /// Weekly XP goal (legacy). Clamped 100…5000 in steps of 100; default 1000.
    var weeklyXPGoalXP: Int {
        get {
            let raw = userDefaults.integer(forKey: Key.weeklyXPGoalXP)
            if raw == 0 {
                return 1_000
            }
            return Self.clampWeeklyGoalStep(raw)
        }
        nonmutating set {
            userDefaults.set(Self.clampWeeklyGoalStep(newValue), forKey: Key.weeklyXPGoalXP)
        }
    }

    private func registerDefaultsIfNeeded() {
        userDefaults.register(defaults: [
            Key.focusDurationMinutes: 25,
            Key.shortRestDurationMinutes: 5,
            Key.longRestDurationMinutes: 15,
            Key.focusDurationSeconds: 25 * 60,
            Key.shortRestDurationSeconds: 5 * 60,
            Key.longRestDurationSeconds: 15 * 60,
            Key.roundsPerSession: 4,
            Key.cyclesPerSession: 1,
            Key.selectedSoundPackIdentifier: "voice-prompts",
            Key.selectedVoiceOption: VoiceOption.defaultSelection.rawValue,
            Key.isAudioMuted: false,
            Key.blockedDomains: [String](),
            Key.blockedBundleIdentifiers: [String](),
            Key.selectedAppShellSection: "history",
            Key.appearancePreference: AppearancePreference.system.rawValue,
            Key.weeklyXPGoalXP: 1_000,
            Key.personalWeeklyMinutesTarget: Self.personalWeeklyMinutesDefault,
            Key.profileDisplayName: Self.profileDisplayNameDefault,
            Key.blockerOnboardingPresented: false
        ])
    }

    private func mirrorBlocklistIntoSuite() {
        guard let suiteDefaults else {
            return
        }
        let domains = userDefaults.stringArray(forKey: Key.blockedDomains) ?? []
        let bundles = userDefaults.stringArray(forKey: Key.blockedBundleIdentifiers) ?? []
        suiteDefaults.set(domains, forKey: BlockerAppGroup.UserDefaultsKey.blockedDomains)
        suiteDefaults.set(bundles, forKey: BlockerAppGroup.UserDefaultsKey.blockedBundleIDs)
        suiteDefaults.synchronize()
        BlockingStateCoordinator.applySharedBlocklistMergeSync(domains: domains, bundleIDs: bundles)
    }
    private func migrateLegacyMinuteDurationsIfNeeded() {
        migrateLegacyDuration(
            legacyMinutesKey: Key.focusDurationMinutes,
            secondsKey: Key.focusDurationSeconds,
            minutesRange: 1...120
        )
        migrateLegacyDuration(
            legacyMinutesKey: Key.shortRestDurationMinutes,
            secondsKey: Key.shortRestDurationSeconds,
            minutesRange: 1...30
        )
        migrateLegacyDuration(
            legacyMinutesKey: Key.longRestDurationMinutes,
            secondsKey: Key.longRestDurationSeconds,
            minutesRange: 1...60
        )
    }

    private func migrateLegacyDuration(
        legacyMinutesKey: String,
        secondsKey: String,
        minutesRange: ClosedRange<Int>
    ) {
        guard userDefaults.object(forKey: legacyMinutesKey) != nil else {
            return
        }
        let legacyMinutes = userDefaults.integer(forKey: legacyMinutesKey)
        let clampedMinutes = Self.clamp(legacyMinutes, within: minutesRange)
        userDefaults.set(clampedMinutes * 60, forKey: secondsKey)
        userDefaults.removeObject(forKey: legacyMinutesKey)
    }

    private static func clamp(_ value: Int, within range: ClosedRange<Int>) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }

    static func clampWeeklyGoalStep(_ value: Int) -> Int {
        let stepped = (max(0, value) / 100) * 100
        return clamp(max(100, stepped), within: 100...5_000)
    }

    private func durationSeconds(
        for secondsKey: String,
        legacyMinutesKey: String,
        minutesRange: ClosedRange<Int>,
        defaultMinutes: Int
    ) -> Int {
        let secondsValue = Self.clampDurationSeconds(userDefaults.integer(forKey: secondsKey), maxMinutes: minutesRange.upperBound)
        if userDefaults.object(forKey: secondsKey) != nil {
            return secondsValue
        }
        if userDefaults.object(forKey: legacyMinutesKey) != nil {
            let legacyMinutes = userDefaults.integer(forKey: legacyMinutesKey)
            let clampedMinutes = Self.clamp(legacyMinutes, within: minutesRange)
            let legacySeconds = clampedMinutes * 60
            let defaultSeconds = defaultMinutes * 60
            if secondsValue == defaultSeconds && legacySeconds != defaultSeconds {
                return legacySeconds
            }
            return legacySeconds
        }
        return secondsValue
    }

    private static func clampDurationSeconds(_ value: Int, maxMinutes: Int) -> Int {
        let clamped = clamp(value, within: 1...(maxMinutes * 60 + 59))
        return clamped
    }
}
