import SwiftUI

struct FirstLaunchOnboardingFlowView: View {
    @ObservedObject var viewModel: FirstLaunchOnboardingFlowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing5) {
            headerMetrics

            MacDSCard {
                Group {
                    switch viewModel.step {
                    case .appOverview:
                        overviewStepContent
                    case .timerExplanation:
                        timerExplanationContent
                    case .blockerExplanation:
                        blockerEducationContent
                    case .blockerPermission:
                        blockerPermissionContent
                    case .notificationsPermission:
                        notificationPermissionContent
                    }
                }
            }

            Spacer(minLength: DesignSpacing.spacing2)

            Divider()
                .overlay(MacDS.Color.dividerLight)

            onboardingFooterControls
        }
        .macDSPagePadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(MacDS.Color.backgroundPrimary)
        .environment(\.appUISurface, .mainWindow)
    }

    private var headerMetrics: some View {
        HStack {
            Text(viewModel.onboardingStepHeading)
                .macDSHelperText()
            Spacer()
            MacDSPillTag(text: "Step \(viewModel.progressLabel)")
        }
    }

    private var overviewStepContent: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing4) {
            Text("Structured focus from the menubar")
                .font(.macDSSectionHeading)
                .foregroundStyle(MacDS.Color.textPrimary)

            explanatoryParagraph([
                "FocusHacker mixes Pomodoro timing, intentional blocking on macOS, and light gamification to keep distraction in check.",
                "You can control everything via the compact menubar popover or reopen this workspace whenever you need deeper settings.",
                "The guided tour completes in around two minutes—take it once, tweak anything later inside Settings."
            ])
        }
    }

    private var timerExplanationContent: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing4) {
            Text("How sessions run")
                .font(.macDSSectionHeading)
                .foregroundStyle(MacDS.Color.textPrimary)

            explanatoryParagraph([
                "You decide how many focus rounds to run between short rests.",
                "An optional long rest anchors the finishing stretch so you decompress before logging XP.",
                "Pause when life interrupts—but ending a session early means no XP is awarded for those rounds.",
                "The menubar shows a green FOCUS pill or red REST pill with your countdown—both flash in the final 20 seconds so you never miss the switch."
            ])
        }
    }

    private var blockerEducationContent: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing4) {
            Text("Blocking that respects your flow")
                .font(.macDSSectionHeading)
                .foregroundStyle(MacDS.Color.textPrimary)

            explanatoryParagraph([
                "During focus, listed apps keep working locally but lose outbound network access until you rest.",
                "Domains you add block by hostname. Try explicit hosts (twitter.com) or suffix wildcards (*.reddit.com).",
                "Nothing is force-quit—if you need a blocked app offline, end focus or remove it from the list.",
                "FocusHacker never leaves filters stuck on: rest periods, completed sessions, and fail-safe shutdown all lift protection."
            ])
        }
    }

    private var blockerPermissionContent: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing4) {
            Text(browserPermissionTitle)
                .font(.macDSSectionHeading)
                .foregroundStyle(MacDS.Color.textPrimary)

            explanatoryParagraph(browserPermissionParagraphs)

            if let error = viewModel.blockerInstallErrorDescription {
                Text(error)
                    .font(.macDSCaption)
                    .foregroundStyle(MacDS.Color.destructive)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: DesignSpacing.spacing2) {
                Button {
                    viewModel.requestBrowserAutomationPermissions()
                } label: {
                    Text("Allow Safari & Chrome control")
                }
                .buttonStyle(MacDSPrimaryButtonStyle())

                Button("Skip for now") {
                    viewModel.skipBlockInstallAndContinue()
                }
                .buttonStyle(MacDSSecondaryButtonStyle())

                Button("Open Automation Settings") {
                    SystemSettingsLinker.openAutomationSettings()
                }
                .buttonStyle(MacDSSecondaryButtonStyle())
            }
            .onAppear {
                viewModel.requestBrowserAutomationPermissions()
            }
        }
    }

    private var browserPermissionTitle: String {
        "Allow FocusHacker to control your browsers"
    }

    private var browserPermissionParagraphs: [String] {
        [
            "During focus, FocusHacker redirects blocked sites in Safari and Google Chrome to a local holding page.",
            "macOS will ask you to allow FocusHacker to control each browser — approve both when prompted.",
            "You can also enable them later under System Settings → Privacy & Security → Automation, or in Settings → Browser blocking."
        ]
    }

    private var notificationPermissionContent: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing4) {
            Text("Stay aware when FocusHacker is in the background")
                .font(.macDSSectionHeading)
                .foregroundStyle(MacDS.Color.textPrimary)

            explanatoryParagraph([
                "Notifications keep you posted about upcoming transitions when the app is not frontmost.",
                "You can grant alerts now, jump to System Settings, or skip—audio cues and the in-app overlay still work while you are here."
            ])

            if let hint = viewModel.notificationDecisionHint {
                Text(
                    hint
                        ? "Notifications enabled — we will keep alerts lightweight."
                        : "Notifications remain off — you can enable them later in System Settings."
                )
                .macDSHelperText()
            }

            HStack(spacing: DesignSpacing.spacing2) {
                Button("Allow notifications") {
                    viewModel.requestNotificationAuthorization()
                }
                .buttonStyle(MacDSPrimaryButtonStyle())

                Button("Not now") {
                    viewModel.continueWithoutNotificationPrompt()
                }
                .buttonStyle(MacDSSecondaryButtonStyle())

                Button("Notification settings…") {
                    SystemSettingsLinker.openNotificationsSettings()
                }
                .buttonStyle(MacDSSecondaryButtonStyle())
            }
        }
    }

    private var onboardingFooterControls: some View {
        HStack(spacing: DesignSpacing.spacing2) {
            Button("Back") {
                viewModel.goBack()
            }
            .buttonStyle(MacDSSecondaryButtonStyle())
            .keyboardShortcut(.cancelAction)
            .disabled(!viewModel.canGoBack)

            Spacer()

            if viewModel.isFinalStep {
                Button("Start using FocusHacker") {
                    viewModel.completeGuidedTour()
                }
                .buttonStyle(MacDSPrimaryButtonStyle())
                .keyboardShortcut(.defaultAction)
            } else {
                Button("Next") {
                    viewModel.goForward()
                }
                .buttonStyle(MacDSPrimaryButtonStyle())
                .keyboardShortcut(.defaultAction)
            }
        }
    }

    private func explanatoryParagraph(_ lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing3) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .macDSHelperText()
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
