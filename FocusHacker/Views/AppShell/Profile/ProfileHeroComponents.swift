import SwiftUI

// MARK: - Profile card palette (spec §2–4; dark hero island in all app appearances)

struct ProfileHeroPalette: Equatable {
    static let cardBorderWidth: CGFloat = 3

    let leftPanel: Color
    let rightPanel: Color
    let statTile: Color
    let mutedLabel: Color
    let primaryText: Color
    let progressLabel: Color
    let pipUnfilled: Color
    let ringOuter: Color
    let ringMid: Color
    let cardBorder: Color
    let cardShadowDepth: Color
    let cardShadowHighlight: Color
    let cardShadowAccentGlow: Color

    static func resolve(for colorScheme: ColorScheme) -> ProfileHeroPalette {
        let accentTeal = MacDS.Resolved.accentTeal(for: colorScheme)
        let isDarkPage = colorScheme == .dark

        return ProfileHeroPalette(
            leftPanel: Color(hex: 0x1C1C1E),
            rightPanel: Color(hex: 0x111111),
            statTile: Color(hex: 0x252527),
            mutedLabel: Color(hex: 0xA8A8A8),
            primaryText: .white,
            progressLabel: Color(hex: 0xA8A8A8),
            pipUnfilled: Color(hex: 0x252527),
            ringOuter: Color(hex: 0x0A0A0A),
            ringMid: Color(hex: 0x1A1A1A),
            cardBorder: accentTeal,
            cardShadowDepth: Color.black.opacity(isDarkPage ? 0.45 : 0.14),
            cardShadowHighlight: Color.white.opacity(isDarkPage ? 0.08 : 0.35),
            cardShadowAccentGlow: accentTeal.opacity(isDarkPage ? 0.18 : 0.12)
        )
    }
}

// MARK: - Hero card elevation (thick frame + layered 3D shadow)

extension View {
    func profileHeroCardElevation(palette: ProfileHeroPalette) -> some View {
        shadow(color: palette.cardShadowDepth, radius: 11, x: 0, y: 6)
            .shadow(color: palette.cardShadowAccentGlow, radius: 8, x: 0, y: 3)
            .shadow(color: palette.cardShadowHighlight, radius: 1, x: 0, y: -1)
    }
}

private struct ProfileHeroPaletteKey: EnvironmentKey {
    static let defaultValue = ProfileHeroPalette.resolve(for: .light)
}

extension EnvironmentValues {
    var profileHeroPalette: ProfileHeroPalette {
        get { self[ProfileHeroPaletteKey.self] }
        set { self[ProfileHeroPaletteKey.self] = newValue }
    }
}

// MARK: - Stat tile

struct ProfileHeroStatBox: View {
    @Environment(\.profileHeroPalette) private var palette

    let title: String
    let systemImage: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(palette.mutedLabel)
                .symbolRenderingMode(.monochrome)
                .labelStyle(.titleAndIcon)
                .lineLimit(1)
                .truncationMode(.tail)
            Text(value)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(palette.primaryText)
                .monospacedDigit()
                .minimumScaleFactor(0.75)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(palette.statTile)
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - XP progress

struct ProfileHeroProgressBlock: View {
    @Environment(\.profileHeroPalette) private var palette

    let label: String
    let amountText: String
    let fraction: Double
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(palette.progressLabel)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(amountText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(accent)
                    .monospacedDigit()
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.85)
            }
            ProfileHeroThinProgressBar(fraction: fraction, accent: accent)
        }
    }
}

struct ProfileHeroThinProgressBar: View {
    @Environment(\.profileHeroPalette) private var palette

    let fraction: Double
    let accent: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(palette.statTile)
                Capsule()
                    .fill(accent)
                    .frame(width: max(0, geometry.size.width * fraction))
            }
        }
        .frame(height: 7)
    }
}

// MARK: - 3D badge (spec §5.2)

struct ProfileHero3DBadge: View {
    @Environment(\.profileHeroPalette) private var palette

    let appearance: FocusBadgeAppearance
    var outerDiameter: CGFloat = 88

    private var scale: CGFloat { outerDiameter / 88 }
    private var midDiameter: CGFloat { 76 * scale }
    private var faceDiameter: CGFloat { 64 * scale }
    private var iconSize: CGFloat { 26 * scale }

    var body: some View {
        ZStack {
            Circle()
                .fill(palette.ringOuter)
                .frame(width: outerDiameter, height: outerDiameter)

            Circle()
                .fill(palette.ringMid)
                .frame(width: midDiameter, height: midDiameter)
                .shadow(color: .white.opacity(0.05), radius: 0, x: 0, y: 2)
                .overlay(
                    Circle()
                        .strokeBorder(Color.black.opacity(0.5), lineWidth: 0.5)
                )

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: appearance.gradientStops,
                            startPoint: UnitPoint(x: 0.2, y: 0),
                            endPoint: UnitPoint(x: 0.85, y: 1)
                        )
                    )
                    .frame(width: faceDiameter, height: faceDiameter)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.black.opacity(0.4), lineWidth: 0)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 0, x: 0, y: 3)

                Ellipse()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 22 * scale, height: 16 * scale)
                    .offset(x: -faceDiameter * 0.12, y: -faceDiameter * 0.22)

                VStack {
                    Spacer()
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, Color.black.opacity(0.28)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: faceDiameter * 0.45)
                }
                .frame(width: faceDiameter, height: faceDiameter)
                .clipShape(Circle())

                Image(systemName: appearance.emblemSymbol)
                    .font(.system(size: iconSize))
                    .foregroundStyle(appearance.iconColor)
            }
            .frame(width: faceDiameter, height: faceDiameter)
            .clipShape(Circle())
        }
        .frame(width: outerDiameter, height: outerDiameter)
        .accessibilityHidden(true)
    }
}

// MARK: - Pip row (spec §5.4)

struct ProfileHeroPipRow: View {
    @Environment(\.profileHeroPalette) private var palette

    let unlockedCount: Int
    let totalSegments: Int
    let accent: Color
    var unfilledColor: Color?

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<totalSegments, id: \.self) { index in
                Capsule()
                    .fill(index < unlockedCount ? accent : (unfilledColor ?? palette.pipUnfilled))
                    .frame(width: 14, height: 4)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(unlockedCount) of \(totalSegments) levels unlocked")
    }
}

// MARK: - Next level pill (spec §5.5)

struct ProfileHeroNextLevelPill: View {
    let nextTitle: String
    let appearance: FocusBadgeAppearance

    var body: some View {
        Text("Next: \(nextTitle) →")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(appearance.pillText)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(Capsule().fill(appearance.pillBackground))
            .overlay(Capsule().stroke(appearance.pillBorder, lineWidth: 1))
            .lineLimit(1)
            .truncationMode(.tail)
    }
}
