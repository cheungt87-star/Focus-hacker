import SwiftUI

@available(macOS 14.0, *)
struct ProfileProgressSection: View {
    @ObservedObject var viewModel: AppShellViewModel

    var body: some View {
        MacDSCard {
            VStack(alignment: .leading, spacing: DesignSpacing.spacing6) {
                HStack(alignment: .center) {
                    Text("Focus hours progress")
                        .font(.macDSCardTitle)
                        .foregroundStyle(MacDS.Color.textPrimary)
                    Spacer(minLength: DesignSpacing.spacing4)
                    chartPeriodToggle
                }

                ProfileFocusChartView(
                    period: viewModel.profileChartPeriod,
                    buckets: viewModel.focusChartBuckets,
                    isLoading: viewModel.focusChartIsLoading,
                    focusHackerDailyTargetMinutes: ProfileChartTargets.mockFocusHackerDailyMinutes,
                    personalDailyTargetMinutes: ProfileChartTargets.mockPersonalDailyMinutes
                )
                .frame(height: 280)
            }
        }
    }

    private var chartPeriodToggle: some View {
        HStack(spacing: 2) {
            ForEach(ProfileChartPeriod.allCases) { period in
                periodSegment(period: period)
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                .fill(MacDS.Color.surfaceDisabled)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Focus hours chart time range")
    }

    private func periodSegment(period: ProfileChartPeriod) -> some View {
        let isSelected = viewModel.profileChartPeriod == period
        return Button {
            guard viewModel.profileChartPeriod != period else { return }
            viewModel.profileChartPeriod = period
            viewModel.refreshFocusChart()
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
