import SwiftUI

@available(macOS 14.0, *)
struct ProfileProgressSection: View {
    @ObservedObject var viewModel: AppShellViewModel

    @State private var selectedBucket: FocusHoursChartBucket?

    var body: some View {
        MacDSCard {
            VStack(alignment: .leading, spacing: DesignSpacing.spacing6) {
                HStack(alignment: .center, spacing: DesignSpacing.spacing4) {
                    Text("Focus hours progress")
                        .font(.macDSCardTitle.weight(.bold))
                        .foregroundStyle(MacDS.Color.textPrimary)
                    Spacer(minLength: DesignSpacing.spacing4)
                    if viewModel.showsProfileChartPeriodNavigation {
                        chartPeriodNavigationPill
                    }
                    chartPeriodToggle
                }

                ProfileFocusChartView(
                    period: viewModel.profileChartPeriod,
                    buckets: viewModel.focusChartBuckets,
                    isLoading: viewModel.focusChartIsLoading,
                    focusHackerDailyTargetMinutes: viewModel.focusHackerDailyTargetMinutes,
                    personalDailyTargetMinutes: viewModel.personalDailyTargetMinutes,
                    lastUpdated: viewModel.focusChartLastUpdated,
                    selectedBucket: $selectedBucket
                )
                .frame(height: 280)
                .padding(.horizontal, DesignSpacing.spacing3)
            }
        }
        .onChange(of: viewModel.profileChartPeriod) { _, _ in
            selectedBucket = nil
        }
        .onChange(of: viewModel.focusChartBuckets.map(\.id)) { _, _ in
            selectedBucket = nil
        }
    }

    private func chartControlPill<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(2)
            .background(
                RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                    .fill(MacDS.Color.surfaceDisabled)
            )
    }

    private var chartPeriodNavigationPill: some View {
        chartControlPill {
            HStack(spacing: 2) {
                chartNavSegment(
                    systemName: "chevron.left",
                    accessibilityLabel: "Previous \(viewModel.profileChartPeriod.accessibilityTitle.lowercased())",
                    action: viewModel.chartNavigatePrevious
                )

                Text(viewModel.profileChartRangeTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MacDS.Color.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(minWidth: 108, maxWidth: 140)
                    .multilineTextAlignment(.center)

                chartNavSegment(
                    systemName: "chevron.right",
                    accessibilityLabel: "Next \(viewModel.profileChartPeriod.accessibilityTitle.lowercased())",
                    action: viewModel.chartNavigateNext,
                    isEnabled: viewModel.canChartNavigateForward
                )
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Chart period navigation")
        .accessibilityValue(viewModel.profileChartRangeTitle)
    }

    private func chartNavSegment(
        systemName: String,
        accessibilityLabel: String,
        action: @escaping () -> Void,
        isEnabled: Bool = true
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isEnabled ? MacDS.Color.textSecondary : MacDS.Color.textSecondary.opacity(0.35))
                .padding(.vertical, DesignSpacing.spacing2)
                .padding(.horizontal, DesignSpacing.spacing3)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isEnabled ? [] : [])
    }

    private var chartPeriodToggle: some View {
        chartControlPill {
            HStack(spacing: 2) {
                ForEach(ProfileChartPeriod.chartToggleCases) { period in
                    periodSegment(period: period)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Focus hours chart time range")
    }

    private func periodSegment(period: ProfileChartPeriod) -> some View {
        let isSelected = viewModel.profileChartPeriod == period
        return Button {
            guard viewModel.profileChartPeriod != period else { return }
            viewModel.selectProfileChartPeriod(period)
        } label: {
            Text(period.shortTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? MacDS.Color.textPrimary : MacDS.Color.textSecondary)
                .padding(.vertical, DesignSpacing.spacing2)
                .padding(.horizontal, DesignSpacing.spacing3)
                .background(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: MacDS.Radius.standard - 2)
                                .fill(MacDS.Color.accentTealLightest)
                                .overlay(
                                    RoundedRectangle(cornerRadius: MacDS.Radius.standard - 2)
                                        .stroke(MacDS.Color.accentTeal, lineWidth: 1)
                                )
                        }
                    }
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(period.accessibilityTitle)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#if DEBUG
@available(macOS 14.0, *)
#Preview("Focus hours progress") {
    ProfileProgressSection(viewModel: AppShellViewModel.profileChartSectionPreview())
        .frame(width: 520)
        .padding()
        .background(MacDS.Color.backgroundPrimary)
}
#endif
