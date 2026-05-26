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

    @State private var progressResetConfirmation = false
    @State private var isEditingProfileName = false
    @State private var profileNameDraft = ""
    @State private var isPersonalTargetEditPresented = false
    @State private var personalTargetDraftHours = 0
    @State private var personalTargetDraftMinutes = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSpacing.spacing5) {
                MacDSSectionHeader(title: "Settings", showsUnderline: false)

                profileSection
                focusSettingsSection
                notificationsAndSoundSection
                blockingSection
                yourAccountSection
                dangerZoneSection
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
        .sheet(isPresented: $isPersonalTargetEditPresented) {
            PersonalWeeklyTargetEditSheet(
                hours: $personalTargetDraftHours,
                minutes: $personalTargetDraftMinutes,
                onCancel: cancelPersonalTargetEdit,
                onSave: savePersonalTargetEdit
            )
        }
    }

    // MARK: - 3. Choose your voice

    private var notificationsAndSoundSection: some View {
        MacDSCard {
            notificationsAndSoundContent
        }
    }

    private var notificationsAndSoundContent: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing4) {
            Text("Choose your voice")
                .font(.macDSCardTitle)
                .foregroundStyle(MacDS.Color.textPrimary)

            VoicePackSelectorView(viewModel: viewModel)

            Divider()
                .overlay(MacDS.Color.dividerLight)

            VStack(alignment: .leading, spacing: DesignSpacing.spacing2) {
                Text("Notification preferences")
                    .font(.macDSLabel)
                    .foregroundStyle(MacDS.Color.textPrimary)
                Text(
                    "Customize when macOS shows notifications and sounds for your focus sessions."
                )
                .macDSHelperText()
                .fixedSize(horizontal: false, vertical: true)
                Button("Review notification preference") {
                    SystemSettingsLinker.openNotificationsSettings()
                }
                .buttonStyle(.plain)
                .font(.macDSLabel)
                .foregroundStyle(MacDS.Color.accentTeal)
            }
        }
    }

    // MARK: - 2. Focus Settings

    private var focusSettingsSection: some View {
        MacDSCard {
            focusSettingsContent
        }
    }

    private var focusSettingsContent: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing4) {
            Text("Your focus targets")
                .font(.macDSCardTitle)
                .foregroundStyle(MacDS.Color.textPrimary)

            Divider()
                .overlay(MacDS.Color.dividerLight)

            hackerGoalSettingsRow

            Divider()
                .overlay(MacDS.Color.dividerLight)

            personalTargetSettingsRow
        }
    }

    private var hackerGoalSettingsRow: some View {
        let targetMinutes = ProfileDashboardMetrics.defaultWeeklyMinutesTarget
        return SettingsFocusTargetRow(
            title: "Hacker goal",
            badge: "preset for all users",
            description: "The hacker bar. Can you hit it every week?",
            value: .minutesOnly(targetMinutes),
            accessibilityLabel:
                "Hacker goal, preset for all users, \(targetMinutes) minutes per week"
        )
    }

    private var personalTargetSettingsRow: some View {
        let targetMinutes = viewModel.personalWeeklyTargetMinutes
        return SettingsFocusTargetRow(
            title: "Personal target",
            badge: nil,
            description: "Your bar. Set it, chase it. Resets every Sunday.",
            value: .minutesOnly(targetMinutes),
            showsChangeLink: true,
            onChange: beginPersonalTargetEdit,
            accessibilityLabel:
                "Personal target, \(PersonalWeeklyTargetFormatting.settingsAccessibilityLabel(totalMinutes: targetMinutes))"
        )
    }

    private func beginPersonalTargetEdit() {
        let parts = PersonalWeeklyTargetFormatting.editorBaselineParts()
        personalTargetDraftHours = parts.hours
        personalTargetDraftMinutes = parts.minutes
        isPersonalTargetEditPresented = true
    }

    private func cancelPersonalTargetEdit() {
        isPersonalTargetEditPresented = false
    }

    private func savePersonalTargetEdit() {
        let normalized = PersonalWeeklyTargetFormatting.normalizedParts(
            hours: personalTargetDraftHours,
            minutes: personalTargetDraftMinutes
        )
        viewModel.applyPersonalWeeklyMinutesTarget(normalized.totalMinutes)
        isPersonalTargetEditPresented = false
    }

    // MARK: - 1. Profile

    private var profileSection: some View {
        MacDSCard {
            profileSettingsSection
        }
    }

    // MARK: - Blocking

    private var blockingSection: some View {
        MacDSCard {
            blockingSectionContent
        }
    }

    private var blockingSectionContent: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing3) {
            Text("Blocking")
                .font(.macDSCardTitle)
                .foregroundStyle(MacDS.Color.textPrimary)

            browserAutomationDescription

            browserBlockingSectionContent
        }
    }

    private var browserAutomationDescription: some View {
        (
            Text("Connected browsers block distracting sites during focus sessions. Manage blocked domains under ")
            + Text("Blocked Items").bold()
            + Text(" in the sidebar.")
        )
        .macDSHelperText()
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Danger zone

    private var dangerZoneSection: some View {
        MacDSCard {
            dangerZoneSectionContent
        }
    }

    private var dangerZoneSectionContent: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing4) {
            HStack(spacing: DesignSpacing.spacing2) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MacDS.Color.destructive)
                    .accessibilityHidden(true)
                Text("Danger zone")
                    .font(.macDSCardTitle)
                    .foregroundStyle(MacDS.Color.destructive)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Danger zone")

            VStack(alignment: .leading, spacing: DesignSpacing.spacing4) {
                dangerZoneRow(
                    title: "Reset all progress",
                    detail: "Clears all sessions, XP, streaks, and chart data on this Mac.",
                    buttonTitle: "Reset…",
                    confirmationTitle: "Reset all progress data?",
                    confirmationMessage: "Sessions, XP, streaks, and focus charts will return to zero. Your display name and app settings stay unchanged.",
                    confirmButtonTitle: "Reset progress",
                    isPresented: $progressResetConfirmation
                ) {
                    viewModel.resetAllGamificationProgress()
                }

                dangerZoneRestoreRow
            }
        }
    }

    private var dangerZoneRestoreRow: some View {
        dangerZoneRow(
            title: "Restore license",
            detail: "Reactivate your Lifetime Access license on a new Mac.",
            buttonTitle: "Restore…",
            isButtonDisabled: !purchaseEntitlements.hasFinishedBootstrap
        ) {
            Task {
                restoreAlertMessage = nil
                do {
                    try await purchaseEntitlements.restorePurchases()
                } catch {
                    restoreAlertMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                }
            }
        }
    }

    private func dangerZoneRow(
        title: String,
        detail: String,
        buttonTitle: String,
        confirmationTitle: String,
        confirmationMessage: String,
        confirmButtonTitle: String,
        isPresented: Binding<Bool>,
        action: @escaping () -> Void
    ) -> some View {
        dangerZoneRow(
            title: title,
            detail: detail,
            buttonTitle: buttonTitle,
            isButtonDisabled: false,
            buttonAction: { isPresented.wrappedValue = true }
        )
        .confirmationDialog(
            confirmationTitle,
            isPresented: isPresented,
            titleVisibility: .visible
        ) {
            Button(confirmButtonTitle, role: .destructive, action: action)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(confirmationMessage)
        }
    }

    private func dangerZoneRow(
        title: String,
        detail: String,
        buttonTitle: String,
        isButtonDisabled: Bool = false,
        buttonAction: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .top, spacing: DesignSpacing.spacing4) {
            VStack(alignment: .leading, spacing: DesignSpacing.spacing2) {
                Text(title)
                    .font(.macDSLabel)
                    .foregroundStyle(MacDS.Color.textPrimary)
                Text(detail)
                    .macDSHelperText()
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(buttonTitle, action: buttonAction)
                .buttonStyle(MacDSDestructiveOutlineButtonStyle())
                .disabled(isButtonDisabled)
        }
    }

    // MARK: - Shared blocks

    private var browserBlockingSectionContent: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing4) {
            VStack(spacing: 0) {
                browserPermissionRow(
                    browserName: "Safari",
                    bundleIdentifier: "com.apple.Safari",
                    state: blockerSettings.safariAutomationState
                )
                Divider()
                    .overlay(MacDS.Color.dividerLight)
                browserPermissionRow(
                    browserName: "Google Chrome",
                    bundleIdentifier: "com.google.Chrome",
                    state: blockerSettings.chromeAutomationState
                )
            }

            Button("Open automation settings") {
                SystemSettingsLinker.openAutomationSettings()
            }
            .buttonStyle(MacDSSecondaryButtonStyle())
        }
    }

    @ViewBuilder
    private func browserPermissionRow(
        browserName: String,
        bundleIdentifier: String,
        state: AutomationPermissionState
    ) -> some View {
        let displayInfo = BlockedAppDisplayInfoResolver.resolve(bundleIdentifier: bundleIdentifier)

        HStack(spacing: DesignSpacing.spacing3) {
            Image(nsImage: displayInfo.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)

            Text(browserName)
                .font(.macDSBody)
                .foregroundStyle(MacDS.Color.textPrimary)

            Spacer()

            browserPermissionStatus(state: state)
        }
        .padding(.vertical, DesignSpacing.spacing2)
    }

    private func browserPermissionStatus(state: AutomationPermissionState) -> some View {
        Group {
            if state == .granted {
                HStack(spacing: DesignSpacing.spacing2) {
                    Circle()
                        .fill(browserConnectedStatusColor)
                        .frame(width: 8, height: 8)
                        .accessibilityHidden(true)

                    Text("Connected")
                        .font(.macDSCaption)
                        .foregroundStyle(browserConnectedStatusColor)
                }
            } else {
                Text(AutomationPermissionPrimer.permissionStatusLabel(for: state))
                    .font(.macDSCaption)
                    .foregroundStyle(MacDS.Color.accentTeal)
            }
        }
    }

    private var browserConnectedStatusColor: Color {
        Color(hex: 0x32D74B)
    }

    private var profileSettingsSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing4) {
            Text("Your hacker name")
                .font(.macDSCardTitle)
                .foregroundStyle(MacDS.Color.textPrimary)

            if isEditingProfileName {
                MacDSTextField(
                    title: "Display name",
                    text: $profileNameDraft,
                    accessibilityLabel: "Profile display name"
                )

                settingsCancelSaveButtons(
                    onCancel: cancelProfileNameEdit,
                    onSave: saveProfileNameEdit
                )
            } else {
                HStack(alignment: .center, spacing: DesignSpacing.spacing3) {
                    Text(viewModel.profileDisplayName)
                        .font(.macDSBody)
                        .foregroundStyle(MacDS.Color.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button("Edit") {
                        beginProfileNameEdit()
                    }
                    .buttonStyle(.plain)
                    .font(.macDSLabel.weight(.medium))
                    .foregroundStyle(MacDS.Color.accentTeal)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Your hacker name, \(viewModel.profileDisplayName)")
            }
        }
    }

    private func beginProfileNameEdit() {
        profileNameDraft = viewModel.profileDisplayName
        isEditingProfileName = true
    }

    private func cancelProfileNameEdit() {
        profileNameDraft = viewModel.profileDisplayName
        isEditingProfileName = false
    }

    private func saveProfileNameEdit() {
        viewModel.profileDisplayName = profileNameDraft
        isEditingProfileName = false
    }

    private func settingsCancelSaveButtons(
        onCancel: @escaping () -> Void,
        onSave: @escaping () -> Void
    ) -> some View {
        HStack(spacing: DesignSpacing.spacing3) {
            Spacer()
            Button("Cancel", action: onCancel)
                .buttonStyle(MacDSSecondaryButtonStyle())
                .keyboardShortcut(.cancelAction)
            Button("Save", action: onSave)
                .buttonStyle(MacDSPrimaryButtonStyle())
                .keyboardShortcut(.defaultAction)
        }
    }

    // MARK: - Your account

    private var yourAccountSection: some View {
        MacDSCard {
            yourAccountSectionContent
        }
    }

    private var yourAccountSectionContent: some View {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        // Placeholder until subscription renewal is wired from StoreKit.
        let nextPaymentDate = "14 Jun 2026"

        return VStack(alignment: .leading, spacing: DesignSpacing.spacing3) {
            Text("Your account")
                .font(.macDSCardTitle)
                .foregroundStyle(MacDS.Color.textPrimary)

            aboutMembershipCard

            aboutDetailRow(label: "Next payment", value: nextPaymentDate)

            aboutDetailRow(label: "Version", value: "\(version) (\(build))")

            Divider()
                .overlay(MacDS.Color.dividerLight)

            aboutPrivacyFooter
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var aboutMembershipCard: some View {
        HStack(alignment: .center, spacing: DesignSpacing.spacing3) {
            VStack(alignment: .leading, spacing: DesignSpacing.spacing1) {
                Text("Your membership")
                    .font(.macDSLabel)
                    .foregroundStyle(MacDS.Color.textSecondary)

                Text("FocusHacker — Annual")
                    .font(.macDSBody.weight(.bold))
                    .foregroundStyle(MacDS.Color.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            aboutMembershipActiveBadge
        }
        .padding(DesignSpacing.spacing3)
        .background(MacDS.Color.inputBackground)
        .clipShape(RoundedRectangle(cornerRadius: MacDS.Radius.standard))
        .overlay(
            RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                .stroke(MacDS.Color.border, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your membership, FocusHacker Annual, Active")
    }

    private var aboutMembershipActiveBadge: some View {
        HStack(spacing: DesignSpacing.spacing1) {
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .accessibilityHidden(true)

            Text("Active")
                .font(.macDSCaption.weight(.semibold))
        }
        .foregroundStyle(aboutMembershipActiveColor)
        .padding(.horizontal, DesignSpacing.spacing2)
        .padding(.vertical, DesignSpacing.spacing1)
        .background(aboutMembershipActiveColor.opacity(0.14))
        .clipShape(Capsule())
        .accessibilityLabel("Active")
    }

    private var aboutMembershipActiveColor: Color {
        Color(hex: 0x32D74B)
    }

    private func aboutDetailRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignSpacing.spacing3) {
            Text(label)
                .font(.macDSLabel)
                .foregroundStyle(MacDS.Color.textSecondary)

            Spacer(minLength: DesignSpacing.spacing3)

            Text(value)
                .font(.macDSBody)
                .foregroundStyle(MacDS.Color.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value)")
    }

    private var aboutPrivacyFooter: some View {
        HStack(alignment: .top, spacing: DesignSpacing.spacing2) {
            Image(systemName: "lock.fill")
                .font(.macDSCaption)
                .foregroundStyle(MacDS.Color.textTertiary)
                .accessibilityHidden(true)

            Text("FocusHacker stores everything locally — no syncing, telemetry, or social layer.")
                .font(.macDSHelper)
                .foregroundStyle(MacDS.Color.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "FocusHacker stores everything locally — no syncing, telemetry, or social layer."
        )
    }

}

// MARK: - Focus target row (settings card layout)

private struct SettingsFocusTargetRow: View {
    enum ValueStyle: Equatable {
        case minutesOnly(Int)
    }

    let title: String
    let badge: String?
    let description: String
    let value: ValueStyle
    var showsChangeLink: Bool = false
    var onChange: (() -> Void)?
    let accessibilityLabel: String

    var body: some View {
        HStack(alignment: .top, spacing: DesignSpacing.spacing4) {
            VStack(alignment: .leading, spacing: DesignSpacing.spacing2) {
                HStack(spacing: DesignSpacing.spacing2) {
                    Text(title)
                        .font(.macDSBody.weight(.semibold))
                        .foregroundStyle(MacDS.Color.textPrimary)

                    if let badge {
                        Text(badge)
                            .font(.macDSCaption)
                            .foregroundStyle(MacDS.Color.textSecondary)
                            .padding(.horizontal, DesignSpacing.spacing2)
                            .padding(.vertical, DesignSpacing.spacing1)
                            .background(MacDS.Color.pillBackground)
                            .clipShape(Capsule())
                            .accessibilityLabel(badge)
                    }
                }

                Text(description)
                    .macDSHelperText()
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: DesignSpacing.spacing2) {
                SettingsFocusTargetValueDisplay(style: value)

                if showsChangeLink, let onChange {
                    Button("Change", action: onChange)
                        .buttonStyle(.plain)
                        .font(.macDSHelper)
                        .foregroundStyle(MacDS.Color.textSecondary)
                        .underline()
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct SettingsFocusTargetValueDisplay: View {
    let style: SettingsFocusTargetRow.ValueStyle

    private static let numberFont = Font.system(size: 22, weight: .semibold)
    private static let unitFont = Font.macDSHelper

    var body: some View {
        switch style {
        case .minutesOnly(let totalMinutes):
            HStack(alignment: .firstTextBaseline, spacing: DesignSpacing.spacing1) {
                Text("\(totalMinutes)")
                    .font(Self.numberFont)
                    .foregroundStyle(MacDS.Color.textPrimary)
                    .monospacedDigit()
                Text("min / wk")
                    .font(Self.unitFont)
                    .foregroundStyle(MacDS.Color.textSecondary)
            }
        }
    }
}
