import SwiftUI

enum SettingsSelectionStyle: Sendable {
    case teal
    case neutral
}

struct SettingsSelectionRow<Trailing: View>: View {
    let title: String
    let symbolName: String?
    let isSelected: Bool
    let showsSelectedBadge: Bool
    let style: SettingsSelectionStyle
    let onSelect: () -> Void
    @ViewBuilder let trailing: () -> Trailing

    init(
        title: String,
        symbolName: String? = nil,
        isSelected: Bool,
        showsSelectedBadge: Bool = true,
        style: SettingsSelectionStyle = .teal,
        onSelect: @escaping () -> Void,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.symbolName = symbolName
        self.isSelected = isSelected
        self.showsSelectedBadge = showsSelectedBadge
        self.style = style
        self.onSelect = onSelect
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: DesignSpacing.spacing3) {
            rowLabel
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture(perform: onSelect)

            trailing()
        }
        .padding(.horizontal, DesignSpacing.spacing3)
        .padding(.vertical, DesignSpacing.spacing3)
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: MacDS.Radius.standard))
        .overlay(
            RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var rowLabel: some View {
        HStack(spacing: DesignSpacing.spacing3) {
            radioIndicator

            if let symbolName {
                Image(systemName: symbolName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(MacDS.Color.textSecondary)
                    .frame(width: 20)
                    .accessibilityHidden(true)
            }

            HStack(spacing: DesignSpacing.spacing2) {
                Text(title)
                    .font(.macDSLabel.weight(.semibold))
                    .foregroundStyle(MacDS.Color.textPrimary)

                if isSelected, showsSelectedBadge {
                    Text("Selected")
                        .font(.macDSCaption.weight(.semibold))
                        .foregroundStyle(MacDS.Color.accentTeal)
                        .padding(.horizontal, DesignSpacing.spacing2)
                        .padding(.vertical, DesignSpacing.spacing1)
                        .background(MacDS.Color.accentTealLightest)
                        .clipShape(RoundedRectangle(cornerRadius: MacDS.Radius.standard))
                        .accessibilityLabel("Selected")
                }
            }

            Spacer(minLength: 0)
        }
    }

    private var radioIndicator: some View {
        ZStack {
            Circle()
                .stroke(radioStrokeColor, lineWidth: isSelected ? 2 : 1.5)
                .frame(width: 18, height: 18)

            if isSelected {
                Circle()
                    .fill(radioFillColor)
                    .frame(width: 8, height: 8)
            }
        }
        .frame(width: 18, height: 18)
        .accessibilityHidden(true)
    }

    private var rowBackground: Color {
        guard isSelected else {
            return MacDS.Color.cardBackground
        }
        switch style {
        case .teal:
            return MacDS.Color.accentTealLightest.opacity(0.35)
        case .neutral:
            return MacDS.Color.textSecondary.opacity(0.12)
        }
    }

    private var borderColor: Color {
        guard isSelected else {
            return MacDS.Color.border
        }
        switch style {
        case .teal:
            return MacDS.Color.accentTeal
        case .neutral:
            return MacDS.Color.border
        }
    }

    private var radioStrokeColor: Color {
        if isSelected {
            switch style {
            case .teal:
                return MacDS.Color.accentTeal
            case .neutral:
                return MacDS.Color.textSecondary
            }
        }
        return MacDS.Color.border
    }

    private var radioFillColor: Color {
        switch style {
        case .teal:
            return MacDS.Color.accentTeal
        case .neutral:
            return MacDS.Color.textSecondary
        }
    }
}

extension SettingsSelectionRow where Trailing == EmptyView {
    init(
        title: String,
        symbolName: String? = nil,
        isSelected: Bool,
        showsSelectedBadge: Bool = true,
        style: SettingsSelectionStyle = .teal,
        onSelect: @escaping () -> Void
    ) {
        self.init(
            title: title,
            symbolName: symbolName,
            isSelected: isSelected,
            showsSelectedBadge: showsSelectedBadge,
            style: style,
            onSelect: onSelect,
            trailing: { EmptyView() }
        )
    }
}
