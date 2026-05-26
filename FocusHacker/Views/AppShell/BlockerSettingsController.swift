import AppKit
import Foundation
import SwiftUI

/// Blocklist editing for domains and blocked native apps.
@MainActor
final class BlockerSettingsController: ObservableObject {
    @Published var blockedDomains: [String]

    @Published var blockedBundleIdentifiers: [String]

    @Published var newBlockedDomainDraft: String = "" {
        didSet { blockedDomainDraftError = nil }
    }

    @Published var newBlockedBundleDraft: String = "" {
        didSet { blockedBundleDraftError = nil }
    }

    @Published var blockedDomainDraftError: String?
    @Published var blockedBundleDraftError: String?

    @Published private(set) var safariAutomationState: AutomationPermissionState = .unknown
    @Published private(set) var chromeAutomationState: AutomationPermissionState = .unknown

    private let settingsStore: UserDefaultsSettingsStore
    private let blockerService: BlockerServiceProtocol

    init(settingsStore: UserDefaultsSettingsStore, blockerService: BlockerServiceProtocol) {
        self.settingsStore = settingsStore
        self.blockerService = blockerService
        self.blockedDomains = settingsStore.blockedDomains
        self.blockedBundleIdentifiers = settingsStore.blockedBundleIdentifiers
        refreshBrowserPermissionStates()
    }

    func refreshBrowserPermissionStates() {
        safariAutomationState = AutomationPermissionPrimer.refreshPermissionState(
            applicationName: BrowserAutomationTarget.safariApplicationName,
            context: "settings",
            policy: .passive
        )
        chromeAutomationState = AutomationPermissionPrimer.refreshPermissionState(
            applicationName: BrowserAutomationTarget.chromeApplicationName,
            context: "settings",
            policy: .passive
        )
    }

    func recheckBrowserPermissions() {
        safariAutomationState = AutomationPermissionPrimer.refreshPermissionState(
            applicationName: BrowserAutomationTarget.safariApplicationName,
            context: "settings_recheck",
            policy: .userInitiated
        )
        chromeAutomationState = AutomationPermissionPrimer.refreshPermissionState(
            applicationName: BrowserAutomationTarget.chromeApplicationName,
            context: "settings_recheck",
            policy: .userInitiated
        )
    }

    func addBlockedDomainFromDraft() {
        let trimmed = newBlockedDomainDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            blockedDomainDraftError = "Enter a hostname or URL."
            return
        }
        guard BlocklistEvaluation.isValidUserDomainPatternEntry(trimmed) else {
            blockedDomainDraftError =
                "Use a hostname (twitter.com), URL, or wildcard (*.reddit.com)."
            return
        }
        blockedDomainDraftError = nil
        blockedDomains += [trimmed]
        newBlockedDomainDraft = ""
        persistBlocklists()
    }

    func addBlockedBundleFromDraft() {
        let trimmed = newBlockedBundleDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            blockedBundleDraftError = "Enter an app bundle ID."
            return
        }
        guard Self.looksLikeBundleIdentifier(trimmed) else {
            blockedBundleDraftError = "Looks invalid — bundle IDs resemble com.developer.app."
            return
        }
        blockedBundleDraftError = nil
        blockedBundleIdentifiers += [trimmed]
        newBlockedBundleDraft = ""
        persistBlocklists()
    }

    func removeBlockedDomains(at offsets: IndexSet) {
        var next = blockedDomains
        next.remove(atOffsets: offsets)
        blockedDomains = next
        persistBlocklists()
    }

    func removeBlockedBundles(at offsets: IndexSet) {
        var next = blockedBundleIdentifiers
        next.remove(atOffsets: offsets)
        blockedBundleIdentifiers = next
        persistBlocklists()
    }

    func pickApplicationForBlocklist() {
        switch AppBundleIdentifierPicker.pickApplication() {
        case .success(let picked):
            if blockedBundleIdentifiers.contains(picked.bundleIdentifier) {
                blockedBundleDraftError = "That app is already blocked."
                return
            }
            blockedBundleDraftError = nil
            blockedBundleIdentifiers += [picked.bundleIdentifier]
            persistBlocklists()
        case .failure(let error):
            switch error {
            case .cancelled:
                break
            case .unreadableBundle:
                blockedBundleDraftError = "Could not read the selected app."
            case .missingBundleIdentifier:
                blockedBundleDraftError = "The selected app has no bundle identifier."
            case .invalidApplication:
                blockedBundleDraftError = "Choose an application (.app), not a folder or file inside it."
            }
        }
    }

    func persistBlocklists() {
        settingsStore.blockedDomains = blockedDomains
        settingsStore.blockedBundleIdentifiers = blockedBundleIdentifiers
        Task {
            await blockerService.refreshBlockedIPLiteralsAfterBlocklistChange()
        }
    }

    func resetBlockedListsToDefaults() {
        blockedDomains = []
        blockedBundleIdentifiers = []
        newBlockedDomainDraft = ""
        newBlockedBundleDraft = ""
        blockedDomainDraftError = nil
        blockedBundleDraftError = nil
        persistBlocklists()
    }

    private static func looksLikeBundleIdentifier(_ candidate: String) -> Bool {
        let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.contains(where: { $0.isWhitespace }) else {
            return false
        }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-."))
        guard trimmed.unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
            return false
        }
        guard trimmed.count >= 3 else {
            return false
        }
        return trimmed.contains(".") && trimmed != "."
    }
}
