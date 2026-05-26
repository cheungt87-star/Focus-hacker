import SwiftUI

@available(macOS 14.0, *)
struct ProfileDashboardView: View {
    @ObservedObject var viewModel: AppShellViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSpacing.spacing6) {
                MacDSSectionHeader(title: "My profile", showsUnderline: false)

                ProfileHeroCard(viewModel: viewModel)
                ProfileWeeklyProgressCard(viewModel: viewModel)
                ProfileProgressSection(viewModel: viewModel)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .macDSPagePadding()
        }
        .background(MacDS.Color.backgroundPrimary)
        .environment(\.appUISurface, .mainWindow)
        .onAppear {
            // #region agent log
            DebugSessionLog82afba.write(
                hypothesisId: "H2",
                location: "ProfileDashboardView.onAppear",
                message: "profile_on_appear_refresh"
            )
            // #endregion
            viewModel.refreshAllProfileData()
        }
    }
}
