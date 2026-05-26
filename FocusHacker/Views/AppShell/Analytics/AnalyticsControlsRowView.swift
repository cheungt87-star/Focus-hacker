import SwiftUI

@available(macOS 14.0, *)
struct AnalyticsControlsRowView: View {
    @ObservedObject var viewModel: AnalyticsDetailViewModel

    var body: some View {
        HStack(alignment: .center, spacing: DesignSpacing.spacing4) {
            monthNavigator
            Spacer(minLength: DesignSpacing.spacing4)
            sortControls
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Session log controls")
    }

    private var monthNavigator: some View {
        chartControlPill {
            HStack(spacing: 2) {
                navButton(
                    systemName: "chevron.left",
                    label: "Previous month",
                    action: viewModel.navigateMonthPrevious
                )

                Text(viewModel.monthRangeTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MacDS.Color.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(minWidth: 108, maxWidth: 140)
                    .multilineTextAlignment(.center)

                navButton(
                    systemName: "chevron.right",
                    label: "Next month",
                    action: viewModel.navigateMonthNext,
                    isEnabled: viewModel.canNavigateMonthForward
                )
            }
        }
    }

    private var sortControls: some View {
        HStack(spacing: DesignSpacing.spacing3) {
            Text("Sort by")
                .font(.macDSLabel)
                .foregroundStyle(MacDS.Color.textSecondary)

            chartControlPill {
                HStack(spacing: 2) {
                    sortChip(title: "Date", key: .date)
                    sortChip(title: "Focus time", key: .focusTime)
                    sortChip(title: "XP gained", key: .xp)
                }
            }

            sortDirectionToggle
        }
    }

    private var sortDirectionToggle: some View {
        chartControlPill {
            HStack(spacing: 2) {
                sortDirectionSegment(title: "Highest", highestFirst: true)
                sortDirectionSegment(title: "Lowest", highestFirst: false)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Sort direction")
    }

    private func sortDirectionSegment(title: String, highestFirst: Bool) -> some View {
        let isSelected = viewModel.isHighestFirst == highestFirst
        return Button {
            viewModel.selectSortDirection(highestFirst: highestFirst)
        } label: {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? Color.fhColorPowerBlue : MacDS.Color.textSecondary)
                .padding(.vertical, DesignSpacing.spacing2)
                .padding(.horizontal, DesignSpacing.spacing3)
                .background(
                    RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                        .fill(isSelected ? Color.fhColorPowerBlue.opacity(0.15) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                        .stroke(isSelected ? Color.fhColorPowerBlue : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) sort direction")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func chartControlPill<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(2)
            .background(
                RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                    .fill(MacDS.Color.surfaceDisabled)
            )
    }

    private func navButton(
        systemName: String,
        label: String,
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
        .accessibilityLabel(label)
    }

    private func sortChip(title: String, key: AnalyticsSessionSortKey) -> some View {
        let isSelected = viewModel.sortKey == key
        return Button {
            viewModel.selectSort(key)
        } label: {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? Color.fhColorPowerBlue : MacDS.Color.textSecondary)
                .padding(.vertical, DesignSpacing.spacing2)
                .padding(.horizontal, DesignSpacing.spacing3)
                .background(
                    RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                        .fill(isSelected ? Color.fhColorPowerBlue.opacity(0.15) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                        .stroke(isSelected ? Color.fhColorPowerBlue : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) sort")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
