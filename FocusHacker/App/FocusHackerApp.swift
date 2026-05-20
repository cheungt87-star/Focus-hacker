import SwiftUI

@main
struct FocusHackerApp: App {
    @NSApplicationDelegateAdaptor(FocusHackerAppDelegate.self) private var applicationDelegate

    @StateObject private var appShellViewModel: AppShellViewModel
    @StateObject private var mainWindowPresenter: MainWindowPresenter
    @StateObject private var purchaseEntitlements: PurchaseEntitlementService

    init() {
        let resolvedDependencies = AppDependencies.live
        _appShellViewModel = StateObject(wrappedValue: AppShellViewModel(dependencies: resolvedDependencies))
        _mainWindowPresenter = StateObject(wrappedValue: MainWindowPresenter())
        _purchaseEntitlements = StateObject(wrappedValue: resolvedDependencies.purchaseEntitlementService)
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
        } label: {
            MenuBarStatusLabel(viewModel: appShellViewModel)
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
