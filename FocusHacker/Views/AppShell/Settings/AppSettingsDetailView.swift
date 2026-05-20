import AppKit
import SwiftUI

struct AppSettingsDetailView: View {
    @ObservedObject var viewModel: AppShellViewModel
    @ObservedObject var blockerSettings: BlockerSettingsController
    @ObservedObject var purchaseEntitlements: PurchaseEntitlementService

    @State private var restoreAlertMessage: String?

    init(viewModel: AppShellViewModel, purchaseEntitlements: PurchaseEntitlementService) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self._blockerSettings = ObservedObject(wrappedValue: viewModel.blockerSettings)
        self._purchaseEntitlements = ObservedObject(wrappedValue: purchaseEntitlements)
    }

    @State private var audioResetConfirmation = false
    @State private var appearanceResetConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSpacing.spacing5) {
                MacDSSectionHeader(title: "Settings", showsUnderline: false)

                MacDSCard {
                    browserBlockingSection
                }

                MacDSResettableSectionRow(
                    title: "Sound & notifications",
                    subtitle: notificationMessagingSubtitle,
                    resetLabel: "Reset audio preset…",
                    isPresented: $audioResetConfirmation,
                    confirmationTitle: "Restore default audio?",
                    confirmationDetail: "Clears mute and restores the bundled voice prompts."
                ) {
                    viewModel.resetSoundAndNotificationsSectionToFactorySettings()
                } content: {
                    soundAndNotificationsContent
                }

                MacDSResettableSectionRow(
                    title: "Appearance",
                    subtitle: "Control how FocusHacker shows up in the Dock.",
                    resetLabel: "Reset appearance…",
                    isPresented: $appearanceResetConfirmation,
                    confirmationTitle: "Reset appearance?",
                    confirmationDetail: "Returns to menubar-first mode."
                ) {
                    viewModel.resetAppearanceSectionToFactorySettings()
                } content: {
                    appearanceContent
                }

                MacDSCard {
                    profileSettingsSection
                }

                MacDSCard {
                    gamificationSettingsSection
                }

                MacDSCard {
                    aboutSection
                }
            }
            .macDSPagePadding()
        }
        .background(MacDS.Color.backgroundPrimary)
        .environment(\.appUISurface, .mainWindow)
        .onAppear {
            blockerSettings.refreshBrowserPermissionStates()
            Task {
                await purchaseEntitlements.reloadLifetimeProductPrice()
                await purchaseEntitlements.refreshEntitlementsFromStore()
            }
        }
        .alert("Restore purchases", isPresented: Binding(
            get: { restoreAlertMessage != nil },
            set: { presented in if !presented { restoreAlertMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(restoreAlertMessage ?? "")
        }
    }

    private var browserBlockingReadinessSubtitle: String {
        if viewModel.isBlockingSetupReady {
            return "Safari and Chrome are allowed — blocked sites redirect during focus."
        }
        return "Allow FocusHacker to control Safari and Google Chrome so website blocking works during focus."
    }

    private var browserBlockingSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing3) {
            Text("Browser blocking")
                .font(.macDSCardTitle)
                .foregroundStyle(MacDS.Color.textPrimary)

            Text(browserBlockingReadinessSubtitle)
                .macDSHelperText()
                .fixedSize(horizontal: false, vertical: true)

            browserBlockingSectionContent
        }
    }

    private var browserBlockingSectionContent: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing4) {
            Text(
                "Manage blocked domains and apps under Blocked Items in the sidebar. Blocking runs only during focus."
            )
            .macDSHelperText()
            .fixedSize(horizontal: false, vertical: true)

            browserPermissionRow(
                browserName: "Safari",
                state: blockerSettings.safariAutomationState
            )
            browserPermissionRow(
                browserName: "Google Chrome",
                state: blockerSettings.chromeAutomationState
            )

            HStack(spacing: DesignSpacing.spacing2) {
                Button("Re-check browser permissions") {
                    blockerSettings.recheckBrowserPermissions()
                }
                .buttonStyle(MacDSSecondaryButtonStyle())

                Button("Open Automation Settings") {
                    SystemSettingsLinker.openAutomationSettings()
                }
                .buttonStyle(MacDSSecondaryButtonStyle())
            }
        }
    }

    private func browserPermissionRow(browserName: String, state: AutomationPermissionState) -> some View {
        HStack {
            Text(browserName)
                .font(.macDSBody)
                .foregroundStyle(MacDS.Color.textPrimary)
            Spacer()
            Text(AutomationPermissionPrimer.permissionStatusLabel(for: state))
                .font(.macDSCaption)
                .foregroundStyle(state == .granted ? MacDS.Color.textSecondary : MacDS.Color.accentTeal)
        }
    }

    private var notificationMessagingSubtitle: String {
        guard viewModel.notificationAuthorizationPromptRecorded else {
            return "Transitions request notification permission automatically when FocusHacker is inactive."
        }
        if viewModel.notificationAuthorizationLastGrantedSnapshot {
            return "macOS alerts are enabled — we only send lightweight transition pings."
        }
        return "macOS alerts are off — prompts are still shown in-app whenever you watch the window."
    }

    private var soundAndNotificationsContent: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing4) {
            Toggle("Mute transition audio", isOn: $viewModel.isAudioMuted)
                .toggleStyle(.switch)

            Picker("Sound pack", selection: $viewModel.selectedSoundPack) {
                ForEach(AudioSoundPack.allCases) { pack in
                    Text(pack.title).tag(pack)
                }
            }
            .pickerStyle(.menu)

            Button("Preview selected sound pack") {
                viewModel.previewSelectedSoundPack()
            }
            .buttonStyle(MacDSSecondaryButtonStyle())
            .disabled(viewModel.isAudioMuted)

            Divider()
                .overlay(MacDS.Color.dividerLight)

            Button("Review notification preference") {
                SystemSettingsLinker.openNotificationsSettings()
            }
            .buttonStyle(.plain)
            .font(.macDSLabel)
            .foregroundStyle(MacDS.Color.accentTeal)
        }
    }

    private var appearanceContent: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing4) {
            Toggle("Show Dock icon", isOn: $viewModel.showsDockIcon)
                .toggleStyle(.switch)
            Text(
                "Turn off for a menubar-only presence. While the Dock icon is hidden, macOS runs FocusHacker as an accessory app and does not show the app’s Help menu; use Blocked Items for your lists and Settings → Browser blocking for permissions."
            )
            .macDSHelperText()
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var profileSettingsSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing4) {
            Text("Profile")
                .font(.macDSCardTitle)
                .foregroundStyle(MacDS.Color.textPrimary)
            Text("Shown at the top of My profile. Stored on this Mac only.")
                .macDSHelperText()
                .fixedSize(horizontal: false, vertical: true)
            MacDSTextField(
                title: "Display name",
                text: $viewModel.profileDisplayName,
                accessibilityLabel: "Profile display name"
            )
        }
    }

    private var gamificationSettingsSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing4) {
            Text("Gamification")
                .font(.macDSCardTitle)
                .foregroundStyle(MacDS.Color.textPrimary)
            Text("Weekly XP goal (Monday–Sunday, your local timezone). Level is evaluated when each week closes.")
                .macDSHelperText()
                .fixedSize(horizontal: false, vertical: true)
            Picker("Weekly XP goal", selection: Binding(
                get: { viewModel.weeklyXPGoalSelection },
                set: { viewModel.applyWeeklyGoalSelection($0) }
            )) {
                ForEach(Array(stride(from: 100, through: 5_000, by: 100)), id: \.self) { value in
                    Text("\(value) XP").tag(value)
                }
            }
            .pickerStyle(.menu)
            .accessibilityLabel("Weekly XP goal")
        }
    }

    private var aboutSection: some View {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"

        let now = Date()

        let statusLine =
            purchaseEntitlements.evaluation.aboutSubtitle(now: now)
            ?? (purchaseEntitlements.evaluation.allowsAppUse
                ? "StoreKit recognises active access." : "Purchases inactive — activate from the Unlock window.")

        return VStack(alignment: .leading, spacing: DesignSpacing.spacing3) {
            Text("About")
                .font(.macDSCardTitle)
                .foregroundStyle(MacDS.Color.textPrimary)

            Text("Version \(version) (\(build))")
                .font(.macDSBody)
                .foregroundStyle(MacDS.Color.textSecondary)

            Text(statusLine)
                .font(.macDSCaption)
                .foregroundStyle(MacDS.Color.accentOrange)
                .fixedSize(horizontal: false, vertical: true)

            Text("FocusHacker stores everything locally — no syncing, telemetry, or social layer.")
                .macDSHelperText()
                .fixedSize(horizontal: false, vertical: true)

            Button("Restore purchases…") {
                Task {
                    restoreAlertMessage = nil
                    do {
                        try await purchaseEntitlements.restorePurchases()
                    } catch {
                        restoreAlertMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    }
                }
            }
            .buttonStyle(MacDSSecondaryButtonStyle())
            .disabled(!purchaseEntitlements.hasFinishedBootstrap)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

}
