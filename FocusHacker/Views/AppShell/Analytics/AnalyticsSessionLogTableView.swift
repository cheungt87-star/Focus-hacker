import SwiftUI

private enum AnalyticsSessionLogColumns {
    static let date: CGFloat = 130
    static let started: CGFloat = 65
    static let ended: CGFloat = 65
    static let status: CGFloat = 115
    static let focusTime: CGFloat = 90
    static let xp: CGFloat = 65
}

@available(macOS 14.0, *)
struct AnalyticsSessionLogTableView: View {
    @ObservedObject var viewModel: AnalyticsDetailViewModel

    var body: some View {
        MacDSCard {
            if viewModel.displayedSessions.isEmpty && !viewModel.isLoading {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    columnHeader
                    ForEach(Array(viewModel.displayedSessions.enumerated()), id: \.element.id) { index, session in
                        if index > 0 {
                            Divider().overlay(MacDS.Color.dividerLight)
                        }
                        AnalyticsSessionLogRowView(
                            session: session,
                            isSelected: viewModel.selectedSessionID == session.id,
                            onTap: { viewModel.toggleRowSelection(id: session.id) }
                        )
                    }
                }
            }
        }
        .redacted(reason: viewModel.isLoading ? .placeholder : [])
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Session log for \(viewModel.monthRangeTitle)")
    }

    private var emptyState: some View {
        Text("No sessions recorded this month.")
            .font(.macDSBody)
            .foregroundStyle(MacDS.Color.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSpacing.spacing10)
            .multilineTextAlignment(.center)
    }

    private var columnHeader: some View {
        HStack(spacing: DesignSpacing.spacing3) {
            headerCell("DATE", width: AnalyticsSessionLogColumns.date, alignment: .leading)
            headerCell("STARTED", width: AnalyticsSessionLogColumns.started, alignment: .leading)
            headerCell("ENDED", width: AnalyticsSessionLogColumns.ended, alignment: .leading)
            headerCell("STATUS", width: AnalyticsSessionLogColumns.status, alignment: .leading)
            headerCell("FOCUS TIME", width: AnalyticsSessionLogColumns.focusTime, alignment: .leading)
            headerCell("XP", width: AnalyticsSessionLogColumns.xp, alignment: .leading)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, DesignSpacing.spacing4)
        .padding(.vertical, DesignSpacing.spacing3)
        .background(MacDS.Color.surfaceDisabled.opacity(0.35))
    }

    private func headerCell(_ title: String, width: CGFloat?, alignment: HorizontalAlignment) -> some View {
        Group {
            if let width {
                Text(title)
                    .frame(width: width, alignment: frameAlignment(for: alignment))
            } else {
                Text(title)
            }
        }
        .font(.macDSLabel)
        .foregroundStyle(MacDS.Color.textSecondary)
    }

    private func frameAlignment(for alignment: HorizontalAlignment) -> Alignment {
        switch alignment {
        case .trailing:
            return .trailing
        default:
            return .leading
        }
    }
}

@available(macOS 14.0, *)
private struct AnalyticsSessionLogRowView: View {
    let session: AnalyticsSessionRecord
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSpacing.spacing3) {
                Text(AnalyticsSessionFormatting.tableDateLabel(for: session.endedAt))
                    .frame(width: AnalyticsSessionLogColumns.date, alignment: .leading)
                    .font(.macDSBody.monospaced())
                    .foregroundStyle(MacDS.Color.textSecondary)

                Text(AnalyticsSessionFormatting.tableTimeLabel(for: session.startedAt))
                    .frame(width: AnalyticsSessionLogColumns.started, alignment: .leading)
                    .font(.macDSBody.monospaced())
                    .foregroundStyle(MacDS.Color.textPrimary)

                Text(AnalyticsSessionFormatting.tableTimeLabel(for: session.endedAt))
                    .frame(width: AnalyticsSessionLogColumns.ended, alignment: .leading)
                    .font(.macDSBody.monospaced())
                    .foregroundStyle(MacDS.Color.textPrimary)

                statusBadge
                    .frame(width: AnalyticsSessionLogColumns.status, alignment: .leading)

                Text(AnalyticsSessionFormatting.focusDuration(minutes: session.focusMinutes))
                    .frame(width: AnalyticsSessionLogColumns.focusTime, alignment: .leading)
                    .font(.macDSBody.monospaced())
                    .foregroundStyle(MacDS.Color.textPrimary)

                xpCell
                    .frame(width: AnalyticsSessionLogColumns.xp, alignment: .leading)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, DesignSpacing.spacing4)
            .padding(.vertical, DesignSpacing.spacing3)
            .frame(minHeight: 44, alignment: .center)
            .background(rowBackground)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var statusBadge: some View {
        let isComplete = session.status == .complete
        let color: Color = isComplete ? Color.fhColorMint : Color.fhColorEmber
        let icon = isComplete ? "checkmark" : "xmark"
        let label = isComplete ? "Complete" : "Abandoned"

        return HStack(spacing: DesignSpacing.spacing1) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .accessibilityHidden(true)
            Text(label)
                .font(.macDSCaption.weight(.semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, DesignSpacing.spacing2)
        .padding(.vertical, DesignSpacing.spacing1)
        .background(color.opacity(0.14))
        .clipShape(Capsule())
    }

    private var xpCell: some View {
        Text("\(session.xpAwarded)")
            .font(.macDSBody.monospaced())
            .foregroundStyle(MacDS.Color.textPrimary)
            .monospacedDigit()
    }

    private var rowBackground: Color {
        switch session.status {
        case .complete:
            if isSelected {
                return MacDS.Color.accentTealLightest
            }
            return Color.clear
        case .abandoned:
            if isSelected {
                return Color.fhColorEmber.opacity(0.12)
            }
            return Color.fhColorEmber.opacity(0.06)
        }
    }

    private var accessibilitySummary: String {
        let status = session.status == .complete ? "Complete" : "Abandoned"
        return "\(status), \(AnalyticsSessionFormatting.focusDuration(minutes: session.focusMinutes)) focus, \(session.xpAwarded) XP"
    }
}
