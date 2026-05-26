import SwiftUI

@main
struct FocusHackerApp: App {
    @NSApplicationDelegateAdaptor(FocusHackerAppDelegate.self) private var applicationDelegate

    @StateObject private var appShellViewModel: AppShellViewModel
    @StateObject private var mainWindowPresenter: MainWindowPresenter
    @StateObject private var purchaseEntitlements: PurchaseEntitlementService

    init() {
        let resolvedDependencies = AppDependencies.live
        let viewModel = AppShellViewModel(dependencies: resolvedDependencies)
        let presenter = MainWindowPresenter()
        let entitlements = resolvedDependencies.purchaseEntitlementService

        if let notifications = resolvedDependencies.transitionNotificationService as? TransitionNotificationService {
            notifications.onViewStatsRequested = { [weak presenter, weak viewModel, weak entitlements] in
                guard let presenter,
                      let viewModel,
                      let entitlements,
                      entitlements.evaluation.allowsAppUse else {
                    return
                }
                if #available(macOS 14.0, *) {
                    presenter.openWindow(viewModel: viewModel, purchaseEntitlements: entitlements)
                }
            }
            notifications.onCompletionNotificationSuppressed = { [weak viewModel] in
                Task { @MainActor in
                    guard let viewModel else { return }
                    let hint = "Enable notifications in System Settings for session alerts."
                    if let existing = viewModel.completionBannerText,
                       !existing.contains(hint) {
                        viewModel.completionBannerText = "\(existing) \(hint)"
                    } else if viewModel.completionBannerText == nil {
                        viewModel.completionBannerText = hint
                    }
                }
            }
        }

        _appShellViewModel = StateObject(wrappedValue: viewModel)
        _mainWindowPresenter = StateObject(wrappedValue: presenter)
        _purchaseEntitlements = StateObject(wrappedValue: entitlements)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarPopoverView(
                viewModel: appShellViewModel,
                purchaseEntitlements: purchaseEntitlements,
                openFullWindow: {
                    guard purchaseEntitlements.evaluation.allowsAppUse else {
                        Task { @MainActor in
                            await coordinatePaywallFromInteractiveSurface()
                        }
                        return
                    }
                    MenuBarExtraPanelController.dismissPopover()
                    appShellViewModel.openSection(.history)
                    if #available(macOS 14.0, *) {
                        mainWindowPresenter.openWindow(
                            viewModel: appShellViewModel,
                            purchaseEntitlements: purchaseEntitlements
                        )
                    }
                },
                presentPaywall: {
                    Task { @MainActor in
                        await coordinatePaywallFromInteractiveSurface()
                    }
                }
            )
            .id(appShellViewModel.appearancePreference)
        } label: {
            MenuBarStatusLabel(viewModel: appShellViewModel)
                .id(appShellViewModel.menuBarLabelRevision)
        }
        .menuBarExtraStyle(.window)
        .commands {
            CommandGroup(after: .help) {
                Button("Open Automation Settings") {
                    SystemSettingsLinker.openAutomationSettings()
                }
            }
        }
    }

    @MainActor
    private func coordinatePaywallFromInteractiveSurface() async {
        let dependencies = AppDependencies.live
        await dependencies.purchaseEntitlementService.reloadLifetimeProductPrice()
        await dependencies.purchaseEntitlementService.refreshEntitlementsFromStore()
        dependencies.paywallWindowPresenter.presentIfLocked(purchaseEntitlements: dependencies.purchaseEntitlementService)
    }
}
