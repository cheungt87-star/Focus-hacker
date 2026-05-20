import SwiftUI

@available(macOS 14.0, *)
struct MainWindowView: View {
    @ObservedObject var viewModel: AppShellViewModel
    @ObservedObject var purchaseEntitlements: PurchaseEntitlementService

    init(viewModel: AppShellViewModel, purchaseEntitlements: PurchaseEntitlementService) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self._purchaseEntitlements = ObservedObject(wrappedValue: purchaseEntitlements)
    }

    var body: some View {
        ZStack {
            NavigationSplitView(columnVisibility: .constant(.all)) {
                sidebar
                    .frame(minWidth: MacDS.Layout.sidebarWidth, idealWidth: MacDS.Layout.sidebarWidth)
                    .background(MacDS.Color.sidebarBackground)
            } detail: {
                detailView
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(MacDS.Color.backgroundPrimary)
            }
            .navigationSplitViewStyle(.balanced)
            .background(MacDS.Color.backgroundPrimary)

            if viewModel.showsEndSessionConfirmation {
                MacDSEndSessionConfirmationPanel(
                    isPresented: $viewModel.showsEndSessionConfirmation,
                    onConfirm: { viewModel.confirmEndSession() }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .zIndex(2)
            }
        }
        .environment(\.appUISurface, .mainWindow)
        .animation(FocusHackerMotion.easeFast, value: viewModel.showsEndSessionConfirmation)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing6) {
            Text("FocusHacker")
                .font(.macDSCardTitle)
                .foregroundStyle(MacDS.Color.textPrimary)
                .padding(.horizontal, DesignSpacing.spacing3)
                .padding(.top, DesignSpacing.spacing6)

            VStack(alignment: .leading, spacing: DesignSpacing.spacing1) {
                ForEach(AppShellSection.allCases) { section in
                    MacDSSidebarNavItem(
                        title: section.title,
                        systemImage: section.systemImage,
                        isSelected: viewModel.selectedSection == section
                    ) {
                        viewModel.selectedSection = section
                    }
                }
            }
            .padding(.horizontal, DesignSpacing.spacing2)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var detailView: some View {
        switch viewModel.selectedSection {
        case .timer:
            TimerSectionView(viewModel: viewModel, purchaseEntitlements: purchaseEntitlements)
        case .blockedItems:
            BlockedItemsDetailView(viewModel: viewModel)
        case .history:
            ProfileDashboardView(viewModel: viewModel)
        case .settings:
            AppSettingsDetailView(viewModel: viewModel, purchaseEntitlements: purchaseEntitlements)
        }
    }
}

@available(macOS 14.0, *)
private struct TimerSectionView: View {
    @ObservedObject var viewModel: AppShellViewModel
    @ObservedObject var purchaseEntitlements: PurchaseEntitlementService

    var body: some View {
        TimerDashboardView(viewModel: viewModel, purchaseEntitlements: purchaseEntitlements)
    }
}

// MARK: - Timer dashboard

private struct TimerDashboardView: View {
    @ObservedObject var viewModel: AppShellViewModel
    @ObservedObject var purchaseEntitlements: PurchaseEntitlementService

    private var timerConfigurationEnabled: Bool {
        viewModel.state.sessionState == .idle
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSpacing.spacing6) {
                MacDSSectionHeader(title: "Timer", showsUnderline: false)

                TimerThreeRowSlabView(
                    viewModel: viewModel,
                    layout: .mainWindow,
                    purchaseAllowsUse: purchaseEntitlements.evaluation.allowsAppUse,
                    onStartSession: { viewModel.startSession() },
                    onPresentPaywall: {
                        Task { @MainActor in
                            let deps = AppDependencies.live
                            await deps.purchaseEntitlementService.reloadLifetimeProductPrice()
                            await deps.purchaseEntitlementService.refreshEntitlementsFromStore()
                            deps.paywallWindowPresenter.presentIfLocked(purchaseEntitlements: deps.purchaseEntitlementService)
                        }
                    },
                    onRequestEndSession: { viewModel.requestEndSession() }
                )

                sessionActionsBlock

                if let banner = viewModel.levelUpBannerText {
                    completionBanner(banner)
                }

                if let banner = viewModel.completionBannerText {
                    completionBanner(banner)
                }

                Divider()
                    .overlay(MacDS.Color.dividerLight)

                configurationBlock
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .macDSPagePadding()
        }
        .scrollContentBackground(.hidden)
        .background(MacDS.Color.backgroundPrimary)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environment(\.appUISurface, .mainWindow)
        .onAppear {
            viewModel.refreshGamificationStats()
        }
    }

    private var sessionActionsBlock: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing3) {
            if !viewModel.shouldShowStartButton {
                HStack(spacing: DesignSpacing.spacing4) {
                    Button("Reset") {
                        viewModel.restartCurrentInterval()
                    }
                    .buttonStyle(MacDSGhostButtonStyle())
                    .disabled(!viewModel.canRestartCurrentInterval)

                    Button("Skip") {
                        viewModel.skipToNextPhase()
                    }
                    .buttonStyle(MacDSGhostButtonStyle())
                    .disabled(!viewModel.canSkipCurrentPhase)
                }
            }
        }
    }

    private func completionBanner(_ text: String) -> some View {
        MacDSCard {
            HStack(spacing: DesignSpacing.spacing3) {
                Image(systemName: "sparkles")
                    .foregroundStyle(MacDS.Color.accentTeal)
                Text(text)
                    .font(.macDSBody.weight(.semibold))
                    .foregroundStyle(MacDS.Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var configurationBlock: some View {
        MacDSCard {
            TimerSessionConfigurationForm(
                viewModel: viewModel,
                isEnabled: timerConfigurationEnabled,
                sectionTitle: "Configure focus session"
            )
        }
    }
}
