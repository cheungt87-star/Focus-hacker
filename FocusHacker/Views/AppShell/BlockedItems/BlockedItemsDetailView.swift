import AppKit
import SwiftUI

private enum BlockedItemsTab: String, CaseIterable, Identifiable {
    case websites
    case apps

    var id: String { rawValue }

    var title: String {
        switch self {
        case .websites: "Websites"
        case .apps: "Apps"
        }
    }
}

struct BlockedItemsDetailView: View {
    @ObservedObject var viewModel: AppShellViewModel
    @ObservedObject var blockerSettings: BlockerSettingsController

    @State private var selectedTab: BlockedItemsTab = .websites
    @State private var blocklistResetConfirmation = false

    init(viewModel: AppShellViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self._blockerSettings = ObservedObject(wrappedValue: viewModel.blockerSettings)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSpacing.spacing5) {
                MacDSSectionHeader(title: "Blocked Items", showsUnderline: false)

                MacDSResettableSectionRow(
                    title: "Blocklist",
                    subtitle: blocklistSubtitle,
                    resetLabel: "Reset blocklist…",
                    isPresented: $blocklistResetConfirmation,
                    confirmationTitle: "Remove every block?",
                    confirmationDetail: "Domains and bundled apps disappear until you add them again."
                ) {
                    viewModel.resetBlocklistSectionToFactorySettings()
                } content: {
                    blockedItemsContent
                }
            }
            .macDSPagePadding()
        }
        .background(MacDS.Color.backgroundPrimary)
        .environment(\.appUISurface, .mainWindow)
    }

    private var blocklistSubtitle: String {
        if viewModel.isBlockingSetupReady {
            return "Edits activate at the start of your next focus interval."
        }
        return "Allow Safari and Chrome under Settings → Browser blocking before website blocking takes effect."
    }

    private var blockedItemsContent: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing4) {
            MacDSTabBar(tabs: BlockedItemsTab.allCases, selection: $selectedTab) { $0.title }

            switch selectedTab {
            case .websites:
                websitesTabContent
            case .apps:
                appsTabContent
            }
        }
    }

    private var websitesTabContent: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing4) {
            Text(
                "Add domains such as twitter.com or patterns like *.reddit.com. Blocking runs only during focus."
            )
            .macDSHelperText()
            .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: DesignSpacing.spacing2) {
                MacDSTextField(title: "Add domain", text: $blockerSettings.newBlockedDomainDraft)
                    .frame(maxWidth: 340)
                Button("Add domain") {
                    blockerSettings.addBlockedDomainFromDraft()
                }
                .buttonStyle(MacDSPrimaryButtonStyle())
            }

            if let domainError = blockerSettings.blockedDomainDraftError {
                Text(domainError)
                    .font(.macDSCaption)
                    .foregroundStyle(MacDS.Color.destructive)
            }

            if blockerSettings.blockedDomains.isEmpty {
                Text("No blocked domains yet.")
                    .macDSHelperText()
            } else {
                blockedDomainsListView
            }
        }
    }

    private var appsTabContent: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing4) {
            Text(
                "During focus, blocked apps can still open. Only sites on your domain blocklist are blocked inside those apps."
            )
            .macDSHelperText()
            .fixedSize(horizontal: false, vertical: true)

            Button("Add app…") {
                blockerSettings.pickApplicationForBlocklist()
            }
            .buttonStyle(MacDSPrimaryButtonStyle())

            if let bundleError = blockerSettings.blockedBundleDraftError {
                Text(bundleError)
                    .font(.macDSCaption)
                    .foregroundStyle(MacDS.Color.destructive)
            }

            if blockerSettings.blockedBundleIdentifiers.isEmpty {
                Text("No blocked apps yet.")
                    .macDSHelperText()
            } else {
                blockedBundlesListView
            }
        }
    }

    private var blockedDomainsListView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(blockerSettings.blockedDomains.enumerated()), id: \.offset) { index, domain in
                if index > 0 {
                    Divider()
                        .overlay(MacDS.Color.dividerLight)
                }
                BlockedDomainListRow(domain: domain) {
                    blockerSettings.removeBlockedDomains(at: IndexSet(integer: index))
                }
            }
        }
    }

    private var blockedBundlesListView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(blockerSettings.blockedBundleIdentifiers.enumerated()), id: \.offset) { index, bundleIdentifier in
                if index > 0 {
                    Divider()
                        .overlay(MacDS.Color.dividerLight)
                }
                BlockedAppListRow(bundleIdentifier: bundleIdentifier) {
                    blockerSettings.removeBlockedBundles(at: IndexSet(integer: index))
                }
            }
        }
    }
}

private struct BlockedAppListRow: View {
    let bundleIdentifier: String
    let removeAction: () -> Void

    @State private var showDeleteConfirmation = false

    var body: some View {
        let displayInfo = BlockedAppDisplayInfoResolver.resolve(bundleIdentifier: bundleIdentifier)
        HStack(alignment: .center, spacing: DesignSpacing.spacing2) {
            Image(nsImage: displayInfo.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 28)
            Text(displayInfo.displayName)
                .font(.macDSBody)
                .foregroundStyle(MacDS.Color.textPrimary)
            Spacer()
            MacDSIconButton(
                systemName: "trash",
                role: .destructive,
                accessibilityLabel: "Remove app",
                action: { showDeleteConfirmation = true }
            )
        }
        .frame(minHeight: 44)
        .confirmationDialog("Remove from blocklist?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive, action: removeAction)
                .keyboardShortcut(.defaultAction)
            Button("Cancel", role: .cancel) { }
                .keyboardShortcut(.cancelAction)
        } message: {
            Text(
                "\"\(displayInfo.displayName)\" will be removed from your blocked apps. " +
                    "Edits apply at the start of your next focus interval."
            )
        }
    }
}

private struct BlockedDomainListRow: View {
    let domain: String
    let removeAction: () -> Void

    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack(alignment: .center) {
            Text(domain)
                .font(.macDSBody.monospaced())
                .foregroundStyle(MacDS.Color.textPrimary)
            Spacer()
            MacDSIconButton(
                systemName: "trash",
                role: .destructive,
                accessibilityLabel: "Remove domain",
                action: { showDeleteConfirmation = true }
            )
        }
        .frame(minHeight: 44)
        .confirmationDialog("Remove from blocklist?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive, action: removeAction)
                .keyboardShortcut(.defaultAction)
            Button("Cancel", role: .cancel) { }
                .keyboardShortcut(.cancelAction)
        } message: {
            Text(
                "\"\(domain)\" will be removed from your blocked domains. " +
                    "Edits apply at the start of your next focus interval."
            )
        }
    }
}
