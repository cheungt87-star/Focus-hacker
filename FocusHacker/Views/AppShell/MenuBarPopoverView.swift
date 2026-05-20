import SwiftUI

struct MenuBarPopoverView: View {
    @ObservedObject var viewModel: AppShellViewModel
    @ObservedObject var purchaseEntitlements: PurchaseEntitlementService
    let openFullWindow: () -> Void
    let presentPaywall: () -> Void

    private var chrome: TimerChromeTheme { viewModel.timerChromeTheme }

    private var timerConfigurationEnabled: Bool {
        viewModel.state.sessionState == .idle
    }

    var body: some View {
        ZStack {
            popoverChromeContent
            if viewModel.showsEndSessionConfirmation {
                EndSessionConfirmationPanel(
                    isPresented: $viewModel.showsEndSessionConfirmation,
                    theme: chrome,
                    onConfirm: { viewModel.confirmEndSession() }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .zIndex(1)
            }
        }
        .animation(FocusHackerMotion.easeFast, value: viewModel.showsEndSessionConfirmation)
    }

    private var popoverChromeContent: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing4) {
            if !purchaseEntitlements.evaluation.allowsAppUse {
                Text("FocusHacker is locked until StoreKit recognises a lifetime purchase or introductory access.")
                    .font(.fhCaption)
                    .foregroundStyle(chrome.accentTimer)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Show unlock window…") {
                    presentPaywall()
                }
                .buttonStyle(.borderedProminent)

                Divider()
                    .background(chrome.borderDefault)
            }

            if let completionBannerText = viewModel.completionBannerText {
                Text(completionBannerText)
                    .font(.fhCaption)
                    .foregroundStyle(Color.fhColorGold)
            }

            TimerThreeRowSlabView(
                viewModel: viewModel,
                layout: .menuBarPopover,
                purchaseAllowsUse: purchaseEntitlements.evaluation.allowsAppUse,
                onStartSession: { viewModel.startSession() },
                onPresentPaywall: { presentPaywall() },
                onRequestEndSession: { viewModel.requestEndSession() }
            )

            HStack(spacing: DesignSpacing.spacing3) {
                Text("Lv \(viewModel.playerLevel)")
                    .font(.fhCaption.weight(.semibold))
                    .foregroundStyle(chrome.textPrimary)
                Text(viewModel.playerLevelTitle)
                    .font(.fhCaption)
                    .foregroundStyle(chrome.textSecondary)
                Spacer(minLength: 0)
                Text("\(viewModel.weeklyXPEarned)/\(viewModel.weeklyXPGoal) XP")
                    .font(.fhCaption.weight(.semibold))
                    .foregroundStyle(Color.fhColorGold)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(maxWidth: .infinity)
                .background(chrome.borderDefault)

            VStack(alignment: .center, spacing: DesignSpacing.spacing4) {
                TimerSessionConfigurationForm(
                    viewModel: viewModel,
                    isEnabled: timerConfigurationEnabled,
                    sectionTitle: "Configure session"
                )

                Divider()
                    .frame(maxWidth: .infinity)
                    .background(chrome.borderDefault)

                VStack(alignment: .center, spacing: DesignSpacing.spacing3) {
                    Button("Open FocusHacker") {
                        openFullWindow()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .disabled(!purchaseEntitlements.evaluation.allowsAppUse)

                    Text("Blocked sites and apps: open the window, then choose Blocked Items. Browser permissions: Settings → Browser blocking.")
                        .font(.fhCaption)
                        .foregroundStyle(chrome.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack {
                        Spacer(minLength: 0)
                        Menu {
                            Button("Quit", role: .destructive) {
                                NSApplication.shared.terminate(nil)
                            }
                        } label: {
                            Label("More options", systemImage: "line.3.horizontal")
                                .labelStyle(.iconOnly)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(chrome.textPrimary)
                                .frame(width: 32, height: 32)
                                .contentShape(Rectangle())
                        }
                        .menuStyle(.borderlessButton)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSpacing.spacing4)
        .frame(width: 384)
        .background(chrome.bgPanel)
        .environment(\.timerChromeTheme, chrome)
        .onAppear {
            viewModel.refreshGamificationStats()
        }
    }
}

// MARK: - End session confirmation (in-window)

/// SwiftUI `.alert` actions are unreliable when presented from a `MenuBarExtra` window on macOS: the
/// sheet can dismiss without invoking the destructive button’s handler. Keeping confirmation in the
/// same window preserves hit testing and guarantees `onConfirm` runs.
struct EndSessionConfirmationPanel: View {
    @Binding var isPresented: Bool
    var theme: TimerChromeTheme
    var onConfirm: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    isPresented = false
                }

            VStack(spacing: DesignSpacing.spacing4) {
                Image(systemName: "circle.grid.cross.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(theme.textPrimary)
                    .accessibilityHidden(true)

                Text("End Session?")
                    .font(.fhBody.weight(.bold))
                    .foregroundStyle(theme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Ending early forfeits all XP - continue?")
                    .font(.fhCaption)
                    .foregroundStyle(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: DesignSpacing.spacing3) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .buttonStyle(TimerBrutalistOutlineButtonStyle(theme: theme))
                    .keyboardShortcut(.cancelAction)

                    Button("End Session") {
                        onConfirm()
                    }
                    .buttonStyle(EndSessionDestructiveOutlineButtonStyle(theme: theme))
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(DesignSpacing.spacing5)
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: DesignRadius.md)
                    .fill(theme.bgPanel)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignRadius.md)
                            .stroke(theme.borderDefault, lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.35), radius: 18, y: 8)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("End session confirmation")
        .onExitCommand {
            isPresented = false
        }
    }
}

private struct EndSessionDestructiveOutlineButtonStyle: ButtonStyle {
    let theme: TimerChromeTheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .textCase(.uppercase)
            .tracking(0.55)
            .foregroundStyle(Color.fhColorCoral)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(theme.borderDefault.opacity(0.9), lineWidth: 1)
                    .background(RoundedRectangle(cornerRadius: 2).fill(Color.clear))
            )
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(FocusHackerMotion.easeFast, value: configuration.isPressed)
    }
}
