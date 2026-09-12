//
//  RoxyTypography.swift
//  Roxy
//

import SwiftUI
import UIKit

/// The type scale, ported step for step from `Type.kt`.
///
/// SwiftUI cannot attach a line height to a `Font` — only to a view, and only as
/// the EXTRA space between lines. So size and weight come from `RoxyFont`, the
/// line height from `.roxyLineHeight(_:)`, both off this one table.
enum RoxyTextStyle {
    case displaySmall
    case headlineSmall
    case titleLarge
    case titleMedium
    case titleSmall
    case bodyLarge
    case bodyMedium
    case bodySmall
    case labelLarge
    case labelMedium
    case labelSmall

    var size: CGFloat {
        switch self {
        case .displaySmall: 32
        case .headlineSmall: 24
        case .titleLarge: 20
        case .titleMedium: 16
        case .titleSmall: 14
        case .bodyLarge: 16
        case .bodyMedium: 14
        case .bodySmall: 12
        case .labelLarge: 14
        case .labelMedium: 12
        case .labelSmall: 11
        }
    }

    var weight: Font.Weight {
        switch self {
        case .displaySmall, .headlineSmall, .titleLarge: .semibold
        case .titleMedium, .titleSmall, .labelLarge, .labelMedium, .labelSmall: .medium
        case .bodyLarge, .bodyMedium, .bodySmall: .regular
        }
    }

    var lineHeight: CGFloat {
        switch self {
        case .displaySmall: 38
        case .headlineSmall: 30
        case .titleLarge: 26
        case .titleMedium: 22
        case .titleSmall: 20
        case .bodyLarge: 24
        case .bodyMedium: 21
        case .bodySmall: 18
        case .labelLarge: 20
        case .labelMedium: 16
        case .labelSmall: 14
        }
    }

    /// Compose calls this `letterSpacing`.
    var tracking: CGFloat {
        switch self {
        case .displaySmall: -0.5
        case .headlineSmall: -0.25
        case .labelMedium: 0.1
        case .labelSmall: 0.2
        default: 0
        }
    }

    var font: Font {
        .system(size: size, weight: weight)
    }

    /// Measured against the rendered font, not a ratio: SF's default leading is
    /// not a fixed multiple of the point size.
    var extraLineSpacing: CGFloat {
        let uiWeight: UIFont.Weight = switch weight {
        case .semibold: .semibold
        case .medium: .medium
        default: .regular
        }
        return max(0, lineHeight - UIFont.systemFont(ofSize: size, weight: uiWeight).lineHeight)
    }
}

enum RoxyFont {
    static let displaySmall = RoxyTextStyle.displaySmall.font
    /// Screen titles — the app's name on the session list, "Settings".
    static let headlineSmall = RoxyTextStyle.headlineSmall.font
    /// Section headings within a screen.
    static let titleLarge = RoxyTextStyle.titleLarge.font
    /// Row titles: a session, a card, a dialog.
    static let titleMedium = RoxyTextStyle.titleMedium.font
    /// Header titles and the names of things in dense chrome.
    static let titleSmall = RoxyTextStyle.titleSmall.font
    /// Transcript copy.
    static let bodyLarge = RoxyTextStyle.bodyLarge.font
    /// Composer input and secondary body copy.
    static let bodyMedium = RoxyTextStyle.bodyMedium.font
    /// Supporting lines under a title: a summary, a connection status.
    static let bodySmall = RoxyTextStyle.bodySmall.font
    /// The label on a filled button.
    static let labelLarge = RoxyTextStyle.labelLarge.font
    /// Labels that name something: a project, a tool, the app itself.
    static let labelMedium = RoxyTextStyle.labelMedium.font
    /// The smallest metadata — counts, timers.
    static let labelSmall = RoxyTextStyle.labelSmall.font

    // The Kotlin writes these as `<style>.copy(fontFamily = mono)`, which keeps
    // the size — hence a variant per style rather than one "mono".

    static let bodyLargeMono = Font.system(size: RoxyTextStyle.bodyLarge.size, design: .monospaced)
    static let bodySmallMono = Font.system(size: RoxyTextStyle.bodySmall.size, design: .monospaced)
    static let labelSmallMono = Font.system(
        size: RoxyTextStyle.labelSmall.size,
        weight: .medium,
        design: .monospaced
    )
}

extension View {
    /// Pair with the matching `RoxyFont` on any text that can wrap.
    func roxyLineHeight(_ style: RoxyTextStyle) -> some View {
        lineSpacing(style.extraLineSpacing)
            .tracking(style.tracking)
    }
}
