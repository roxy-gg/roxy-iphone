//
//  RoxyPalette.swift
//  Roxy
//

import SwiftUI

/// The design tokens, matching `Color.kt` value for value.
///
/// `white` and `black` are POLARITY tokens, not literal colors: "what a wash is
/// mixed from" and "what sits on a primary button". The light theme swaps them.
struct RoxyPalette: Sendable {
    // Surfaces
    let bg: Color
    let surface: Color
    let surface2: Color
    let elevated: Color

    // Lines
    let border: Color
    let borderStrong: Color

    // Text
    let text: Color
    let textMuted: Color
    let textSubtle: Color

    // Accents
    let accent: Color
    let accentHover: Color
    let success: Color
    let warning: Color
    let danger: Color

    // Polarity
    let white: Color
    let black: Color

    let isDark: Bool
}

extension RoxyPalette {
    static let dark = RoxyPalette(
        bg: Color(hex: 0x0A0A0A),
        surface: Color(hex: 0x0F0F10),
        surface2: Color(hex: 0x161618),
        elevated: Color(hex: 0x1D1D20),
        border: Color(hex: 0x232326),
        borderStrong: Color(hex: 0x303035),
        text: Color(hex: 0xEDEDED),
        textMuted: Color(hex: 0x9A9AA3),
        textSubtle: Color(hex: 0x6A6A73),
        accent: Color(hex: 0x4D8DFF),
        accentHover: Color(hex: 0x6AA0FF),
        success: Color(hex: 0x3FB950),
        warning: Color(hex: 0xD9A441),
        danger: Color(hex: 0xF0556A),
        white: Color(hex: 0xFFFFFF),
        black: Color(hex: 0x000000),
        isDark: true
    )

    static let light = RoxyPalette(
        bg: Color(hex: 0xFFFFFF),
        surface: Color(hex: 0xF7F7F8),
        surface2: Color(hex: 0xEFEFF1),
        elevated: Color(hex: 0xFFFFFF),
        border: Color(hex: 0xE2E2E5),
        borderStrong: Color(hex: 0xC9C9CF),
        text: Color(hex: 0x1A1A1C),
        textMuted: Color(hex: 0x5C5C66),
        textSubtle: Color(hex: 0x8A8A94),
        accent: Color(hex: 0x2563EB),
        accentHover: Color(hex: 0x1D4ED8),
        success: Color(hex: 0x177D3C),
        warning: Color(hex: 0x9A6700),
        danger: Color(hex: 0xC81E3D),
        white: Color(hex: 0x18181B),
        black: Color(hex: 0xFFFFFF),
        isDark: false
    )

    static func resolve(for scheme: ColorScheme) -> RoxyPalette {
        scheme == .dark ? .dark : .light
    }
}

// MARK: - Edges and elevation

extension RoxyPalette {
    /// Translucent, not a fixed grey, so one token is right on every surface.
    var edge: Color { white.opacity(isDark ? 0.05 : 0.08) }

    /// Hover, focus, and anything that floats.
    var edgeStrong: Color { white.opacity(isDark ? 0.09 : 0.14) }

    /// A lit top edge is a dark-UI cue; on paper a soft shadow is the convincing
    /// signal, so the light theme drops it and lets shadows carry depth.
    var edgeLit: Color { isDark ? white.opacity(0.07) : .clear }

    /// Parity only — SwiftUI derives the selection background from the tint,
    /// which `RoxyTheme` already sets to `accent`.
    var selection: Color { accent.opacity(0.30) }

    // `scrollbarThumb` / `scrollbarThumbHover` are not ported: iOS scroll
    // indicators are not styleable.

    /// Tight and weak on purpose: against a near-black page a wide ambient
    /// shadow reads as a grey halo, not depth.
    var raisedShadow: RoxyShadow {
        RoxyShadow(color: .black.opacity(isDark ? 0.06 : 0.05), radius: 1, y: 1)
    }

    /// Detached things: the contact layer plus a short throw.
    var floatShadows: [RoxyShadow] {
        [
            RoxyShadow(color: .black.opacity(isDark ? 0.07 : 0.06), radius: 1, y: 1),
            RoxyShadow(color: .black.opacity(isDark ? 0.09 : 0.07), radius: 6, y: 4)
        ]
    }
}

/// Literal black, never the `black` polarity token: shadow is dark in every
/// theme, and a light theme sets that token to near-white.
struct RoxyShadow: Sendable {
    let color: Color
    let radius: CGFloat
    let y: CGFloat
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
