import SwiftUI

struct FocusBadgeHeroBackground<Content: View>: View {
    let appearance: FocusBadgeAppearance
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(heroGradient)
            .clipShape(RoundedRectangle(cornerRadius: MacDS.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: MacDS.Radius.card)
                    .stroke(appearance.borderColor.opacity(borderOpacity), lineWidth: appearance.borderWidth)
            )
            .shadow(color: appearance.glowColor.opacity(0.45), radius: glowRadius, y: 2)
            .macDSCardShadow()
    }

    private var heroGradient: some View {
        LinearGradient(
            colors: appearance.gradientStops,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var borderOpacity: Double {
        appearance.borderWidth > 0 ? 0.65 : 0
    }

    private var glowRadius: CGFloat {
        appearance.level >= 7 ? 14 : 10
    }
}

struct FocusBadgeEmblem: View {
    let appearance: FocusBadgeAppearance
    var diameter: CGFloat = 140
    var symbolSize: CGFloat = 52

    var body: some View {
        ZStack {
            Circle()
                .fill(appearance.glowColor.opacity(0.35))
                .frame(width: diameter, height: diameter)
            Circle()
                .stroke(appearance.borderColor.opacity(0.5), lineWidth: 2)
                .frame(width: diameter, height: diameter)
            Image(systemName: appearance.emblemSymbol)
                .font(.system(size: symbolSize))
                .foregroundStyle(appearance.progressTint)
                .shadow(color: emblemShadowColor, radius: 2, y: 1)
        }
        .accessibilityHidden(true)
    }

    private var emblemShadowColor: Color {
        appearance.level <= 6 ? .black.opacity(0.15) : .black.opacity(0.35)
    }
}

struct FocusBadgeLevelUpBanner: View {
    let text: String
    let appearance: FocusBadgeAppearance

    var body: some View {
        HStack(spacing: DesignSpacing.spacing3) {
            FocusBadgeEmblem(appearance: appearance, diameter: 44, symbolSize: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.macDSBody.weight(.semibold))
                    .foregroundStyle(appearance.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                if let subtitle = appearance.subtitle {
                    Text(subtitle)
                        .font(.macDSCaption.weight(.medium))
                        .foregroundStyle(appearance.secondaryText.opacity(0.9))
                }
            }
            Spacer(minLength: 0)
        }
        .padding(DesignSpacing.spacing5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: appearance.gradientStops,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: MacDS.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: MacDS.Radius.card)
                .stroke(appearance.borderColor.opacity(0.55), lineWidth: max(1, appearance.borderWidth))
        )
        .shadow(color: appearance.glowColor.opacity(0.35), radius: 8, y: 2)
    }
}
