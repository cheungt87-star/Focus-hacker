import SwiftUI

/// Visual styling per lifetime XP badge tier (`focushacker-profile-card-spec.md` §7).
struct FocusBadgeAppearance: Sendable, Equatable {
    let level: Int
    let gradientStopHexes: [UInt32]
    let borderHex: UInt32
    let borderWidth: CGFloat
    let glowHex: UInt32
    let primaryTextHex: UInt32
    let secondaryTextHex: UInt32
    let progressTintHex: UInt32
    let subtitle: String?
    let emblemSymbol: String

    /// Profile card accent (XP bar, filled pips, progress amount).
    let accentHex: UInt32
    /// Badge icon colour on the 3D face.
    let iconColorHex: UInt32
    let iconColorOpacity: Double
    let pillBackgroundHex: UInt32
    let pillBackgroundOpacity: Double
    let pillBorderHex: UInt32
    let pillBorderOpacity: Double
    let pillTextHex: UInt32

    var gradientStops: [Color] {
        gradientStopHexes.map { Color(hex: $0) }
    }

    var borderColor: Color { Color(hex: borderHex) }
    var glowColor: Color { Color(hex: glowHex) }
    var primaryText: Color { Color(hex: primaryTextHex) }
    var secondaryText: Color { Color(hex: secondaryTextHex) }
    var progressTint: Color { Color(hex: progressTintHex) }
    var accentColor: Color { Color(hex: accentHex) }
    var iconColor: Color { Color(hex: iconColorHex).opacity(iconColorOpacity) }
    var pillBackground: Color { Color(hex: pillBackgroundHex).opacity(pillBackgroundOpacity) }
    var pillBorder: Color { Color(hex: pillBorderHex).opacity(pillBorderOpacity) }
    var pillText: Color { Color(hex: pillTextHex) }

    /// Opacity for the level gradient wash over the profile card right panel (`#111` base).
    static let badgePanelGradientOpacity: Double = 0.25
    /// Opacity for the vertical divider between the stats panel and badge panel.
    static let badgePanelDividerOpacity: Double = 0.35

    /// Multi-stop gradient matching the 3D badge face angle, for tinting the right panel.
    func badgePanelGradient(opacity: Double = badgePanelGradientOpacity) -> LinearGradient {
        LinearGradient(
            colors: gradientStops.map { $0.opacity(opacity) },
            startPoint: UnitPoint(x: 0.2, y: 0),
            endPoint: UnitPoint(x: 0.85, y: 1)
        )
    }

    static func forLevel(_ level: Int) -> FocusBadgeAppearance {
        appearancesByLevel[level] ?? appearancesByLevel[0]!
    }

    static func forBadge(_ badge: FocusBadge) -> FocusBadgeAppearance {
        forLevel(badge.level)
    }

    static func forTotalXP(_ totalXP: Int) -> FocusBadgeAppearance {
        forBadge(FocusBadgeProgression.badge(forTotalXP: totalXP))
    }

    // MARK: - Tier definitions

    private static let appearancesByLevel: [Int: FocusBadgeAppearance] = {
        let entries: [FocusBadgeAppearance] = [
            newcomer,
            rookie,
            amateur,
            semiPro,
            professional,
            allStar,
            champion,
            elite,
            hallOfFamer,
            legend,
            goat
        ]
        return Dictionary(uniqueKeysWithValues: entries.map { ($0.level, $0) })
    }()

    /// Level 0 — Newcomer (spec green gradient, sparkles).
    private static let newcomer = tier(
        level: 0,
        gradient: [0x25A876, 0x1DB97C, 0x0F8A5A],
        border: 0x1DB97C,
        borderWidth: 0,
        glow: 0x1DB97C,
        primaryText: 0xFFFFFF,
        secondaryText: 0xDFE6E9,
        progressTint: 0x1DB97C,
        subtitle: nil,
        emblem: "sparkles",
        accent: 0x1DB97C,
        icon: 0xFFFFFF,
        iconOpacity: 0.92,
        pillBg: 0x1DB97C,
        pillBgOpacity: 0.10,
        pillBorder: 0x1DB97C,
        pillBorderOpacity: 0.25,
        pillText: 0x1DB97C
    )

    /// Level 1 — Rookie (trophy).
    private static let rookie = tier(
        level: 1,
        gradient: [0xBFDBFE, 0x93C5FD, 0x3B82F6],
        border: 0x93C5FD,
        borderWidth: 0,
        glow: 0x60A5FA,
        primaryText: 0x1E3A8A,
        secondaryText: 0x475569,
        progressTint: 0x60A5FA,
        subtitle: nil,
        emblem: "trophy.fill",
        accent: 0x60A5FA,
        icon: 0x1E3A8A,
        iconOpacity: 1,
        pillBg: 0x3B82F6,
        pillBgOpacity: 0.12,
        pillBorder: 0x3B82F6,
        pillBorderOpacity: 0.30,
        pillText: 0x60A5FA
    )

    /// Level 2 — Amateur (star).
    private static let amateur = tier(
        level: 2,
        gradient: [0xBBF7D0, 0x86EFAC, 0x22C55E],
        border: 0x86EFAC,
        borderWidth: 0,
        glow: 0x4ADE80,
        primaryText: 0x14532D,
        secondaryText: 0x475569,
        progressTint: 0x4ADE80,
        subtitle: nil,
        emblem: "star.fill",
        accent: 0x4ADE80,
        icon: 0x14532D,
        iconOpacity: 1,
        pillBg: 0x22C55E,
        pillBgOpacity: 0.12,
        pillBorder: 0x22C55E,
        pillBorderOpacity: 0.30,
        pillText: 0x4ADE80
    )

    /// Level 3 — Semi-Pro (medal).
    private static let semiPro = tier(
        level: 3,
        gradient: [0xDD6F1F, 0xC4730A, 0x8B4513],
        border: 0xFB923C,
        borderWidth: 1,
        glow: 0xDD6F1F,
        primaryText: 0xFFEDD5,
        secondaryText: 0xFED7AA,
        progressTint: 0xDD6F1F,
        subtitle: "Bronze",
        emblem: "medal.fill",
        accent: 0xDD6F1F,
        icon: 0xFFDCB4,
        iconOpacity: 0.90,
        pillBg: 0xDD6F1F,
        pillBgOpacity: 0.12,
        pillBorder: 0xDD6F1F,
        pillBorderOpacity: 0.30,
        pillText: 0xDD6F1F
    )

    /// Level 4 — Professional (briefcase).
    private static let professional = tier(
        level: 4,
        gradient: [0xF5F5F5, 0xD3D3D3, 0xA9A9A9],
        border: 0xFFFFFF,
        borderWidth: 1,
        glow: 0xA9A9A9,
        primaryText: 0x2A2A2A,
        secondaryText: 0x4B5563,
        progressTint: 0xA9A9A9,
        subtitle: "Silver",
        emblem: "briefcase.fill",
        accent: 0xA9A9A9,
        icon: 0x2A2A2A,
        iconOpacity: 1,
        pillBg: 0xA9A9A9,
        pillBgOpacity: 0.12,
        pillBorder: 0xA9A9A9,
        pillBorderOpacity: 0.30,
        pillText: 0xAAAAAA
    )

    /// Level 5 — All-Star (crown).
    private static let allStar = tier(
        level: 5,
        gradient: [0xFFD700, 0xFFED4E, 0xDAA520],
        border: 0xFDE047,
        borderWidth: 1,
        glow: 0xFFD700,
        primaryText: 0x4A3500,
        secondaryText: 0x854D0E,
        progressTint: 0xFFD700,
        subtitle: "Gold",
        emblem: "crown.fill",
        accent: 0xFFD700,
        icon: 0x4A3500,
        iconOpacity: 1,
        pillBg: 0xFFD700,
        pillBgOpacity: 0.12,
        pillBorder: 0xFFD700,
        pillBorderOpacity: 0.30,
        pillText: 0xDAA520
    )

    /// Level 6 — Champion (shield).
    private static let champion = tier(
        level: 6,
        gradient: [0xF0F0F0, 0xE0E0E0, 0xB0B8C0],
        border: 0xD1D5DB,
        borderWidth: 2,
        glow: 0xB0B8C0,
        primaryText: 0x1A2030,
        secondaryText: 0x374151,
        progressTint: 0xB0B8C0,
        subtitle: "Platinum",
        emblem: "shield.fill",
        accent: 0xB0B8C0,
        icon: 0x1A2030,
        iconOpacity: 1,
        pillBg: 0xB0B8C0,
        pillBgOpacity: 0.12,
        pillBorder: 0xB0B8C0,
        pillBorderOpacity: 0.30,
        pillText: 0x8090A8
    )

    /// Level 7 — Elite (diamond).
    private static let elite = tier(
        level: 7,
        gradient: [0x1E3A8A, 0x1D4ED8, 0x0891B2],
        border: 0x22D3EE,
        borderWidth: 2,
        glow: 0x38BDF8,
        primaryText: 0xFFFFFF,
        secondaryText: 0xA5F3FC,
        progressTint: 0x38BDF8,
        subtitle: "Sapphire",
        emblem: "diamond.fill",
        accent: 0x38BDF8,
        icon: 0xBAE6FD,
        iconOpacity: 0.92,
        pillBg: 0x38BDF8,
        pillBgOpacity: 0.10,
        pillBorder: 0x38BDF8,
        pillBorderOpacity: 0.30,
        pillText: 0x38BDF8
    )

    /// Level 8 — Hall of Famer (certificate / seal).
    private static let hallOfFamer = tier(
        level: 8,
        gradient: [0x14532D, 0x15803D, 0x059669],
        border: 0x34D399,
        borderWidth: 2,
        glow: 0x34D399,
        primaryText: 0xFFFFFF,
        secondaryText: 0xA7F3D0,
        progressTint: 0x34D399,
        subtitle: "Emerald",
        emblem: "seal.fill",
        accent: 0x34D399,
        icon: 0xA7F3D0,
        iconOpacity: 0.92,
        pillBg: 0x34D399,
        pillBgOpacity: 0.10,
        pillBorder: 0x34D399,
        pillBorderOpacity: 0.30,
        pillText: 0x34D399
    )

    /// Level 9 — Legend (flame).
    private static let legend = tier(
        level: 9,
        gradient: [0x7F1D1D, 0x991B1B, 0xBE123C],
        border: 0xFB7185,
        borderWidth: 2,
        glow: 0xFB7185,
        primaryText: 0xFFFFFF,
        secondaryText: 0xFECDD3,
        progressTint: 0xFB7185,
        subtitle: "Ruby",
        emblem: "flame.fill",
        accent: 0xFB7185,
        icon: 0xFECDD3,
        iconOpacity: 0.92,
        pillBg: 0xFB7185,
        pillBgOpacity: 0.10,
        pillBorder: 0xFB7185,
        pillBorderOpacity: 0.30,
        pillText: 0xFB7185
    )

    /// Level 10 — GOAT (crown, dark gradient).
    private static let goat = tier(
        level: 10,
        gradient: [0x020617, 0x0F172A, 0x1E293B],
        border: 0xFACC15,
        borderWidth: 2,
        glow: 0xFBBF24,
        primaryText: 0xFDE047,
        secondaryText: 0xFDE047,
        progressTint: 0xFBBF24,
        subtitle: "Black Diamond",
        emblem: "crown.fill",
        accent: 0xFBBF24,
        icon: 0xFDE047,
        iconOpacity: 0.95,
        pillBg: 0xFBBF24,
        pillBgOpacity: 0.12,
        pillBorder: 0xFBBF24,
        pillBorderOpacity: 0.40,
        pillText: 0xFBBF24
    )

    private static func tier(
        level: Int,
        gradient: [UInt32],
        border: UInt32,
        borderWidth: CGFloat,
        glow: UInt32,
        primaryText: UInt32,
        secondaryText: UInt32,
        progressTint: UInt32,
        subtitle: String?,
        emblem: String,
        accent: UInt32,
        icon: UInt32,
        iconOpacity: Double,
        pillBg: UInt32,
        pillBgOpacity: Double,
        pillBorder: UInt32,
        pillBorderOpacity: Double,
        pillText: UInt32
    ) -> FocusBadgeAppearance {
        FocusBadgeAppearance(
            level: level,
            gradientStopHexes: gradient,
            borderHex: border,
            borderWidth: borderWidth,
            glowHex: glow,
            primaryTextHex: primaryText,
            secondaryTextHex: secondaryText,
            progressTintHex: progressTint,
            subtitle: subtitle,
            emblemSymbol: emblem,
            accentHex: accent,
            iconColorHex: icon,
            iconColorOpacity: iconOpacity,
            pillBackgroundHex: pillBg,
            pillBackgroundOpacity: pillBgOpacity,
            pillBorderHex: pillBorder,
            pillBorderOpacity: pillBorderOpacity,
            pillTextHex: pillText
        )
    }
}
