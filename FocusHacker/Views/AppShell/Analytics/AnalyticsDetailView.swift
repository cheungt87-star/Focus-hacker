import SwiftUI

@available(macOS 14.0, *)
struct AnalyticsDetailView: View {
    @ObservedObject var appViewModel: AppShellViewModel
    @StateObject private var analyticsViewModel: AnalyticsDetailViewModel

    init(viewModel: AppShellViewModel) {
        _appViewModel = ObservedObject(wrappedValue: viewModel)
        _analyticsViewModel = StateObject(
            wrappedValue: AnalyticsDetailViewModel(
                analyticsSessionReader: viewModel.dependencies.analyticsSessionReader
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSpacing.spacing6) {
                header
                AnalyticsSummaryStatCardsView(summary: analyticsViewModel.monthSummary)
                AnalyticsControlsRowView(viewModel: analyticsViewModel)
                AnalyticsSessionLogTableView(viewModel: analyticsViewModel)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .macDSPagePadding()
        }
        .background(MacDS.Color.backgroundPrimary)
        .environment(\.appUISurface, .mainWindow)
        .task(id: appViewModel.analyticsRefreshToken) {
            await analyticsViewModel.loadSessions()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing2) {
            Text("Session log")
                .font(.macDSPageTitle)
                .foregroundStyle(MacDS.Color.textPrimary)

            Text("Your focus history, month by month")
                .macDSHelperText()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Session log. Your focus history, month by month.")
    }
}
