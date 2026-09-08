//
//  Theme.swift
//  Roxy
//

import SwiftUI

// MARK: - Shapes

/// Matches `RoxyShapes` in `Theme.kt`. Note `extraLarge` is 22, not Material's
/// default 28 — the Kotlin overrides it, and the composer sits on that step.
enum RoxyRadius {
    static let extraSmall: CGFloat = 6
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let extraLarge: CGFloat = 22

    static func shape(_ radius: CGFloat) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }
}

/// How lit an edge is.
enum RoxyEdgeStyle {
    /// Resting.
    case normal
    /// Hover, focus, and anything floating above the page.
    case strong
    /// A semantic border that must not be quietly turned grey.
    case tinted(Color)
}

/// How far the top-lit highlight fades — roughly 1.5x the control's height, so a
/// button stays lit across its face while a panel gets a lip along the top.
enum RoxyBevelSpan {
    static let control: CGFloat = 48
    static let panel: CGFloat = 120
}

private struct RoxyEdge: ViewModifier {
    @Environment(\.roxyPalette) private var palette

    let radius: CGFloat
    let style: RoxyEdgeStyle
    let bevelSpan: CGFloat

    func body(content: Content) -> some View {
        content.overlay {
            GeometryReader { proxy in
                // A brighter stroke over the hairline, fading to it over
                // `bevelSpan` — one gradient, since a stroke takes one.
                let fade = min(1, bevelSpan / max(proxy.size.height, 1))
                RoxyRadius.shape(radius)
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: topColor, location: 0),
                                .init(color: baseColor, location: fade)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
        }
    }

    private var baseColor: Color {
        switch style {
        case .normal: palette.edge
        case .strong: palette.edgeStrong
        case .tinted(let color): color
        }
    }

    /// A tinted edge means something, so the highlight must not wash it out.
    private var topColor: Color {
        if case .tinted = style { return baseColor }
        return palette.edgeLit == .clear ? baseColor : palette.edgeLit
    }
}

/// Not SwiftUI's `Divider`, which draws one physical pixel — 0.33pt at 3x, a
/// third of `HorizontalDivider`'s 1.dp, thin enough to read as a missing line.
struct RoxyDivider: View {
    @Environment(\.roxyPalette) private var palette

    var color: Color?

    var body: some View {
        Rectangle()
            .fill(color ?? palette.border)
            .frame(height: 1)
    }
}

extension View {
    /// A hairline lit from above. At these alphas you should not be able to
    /// point at the effect — a visible highlight has gone too far.
    func roxyEdge(
        radius: CGFloat,
        style: RoxyEdgeStyle = .normal,
        bevelSpan: CGFloat = RoxyBevelSpan.control
    ) -> some View {
        modifier(RoxyEdge(radius: radius, style: style, bevelSpan: bevelSpan))
    }

    /// The shape most of the app is built from.
    func roxySurface(
        _ fill: Color,
        radius: CGFloat,
        edge: RoxyEdgeStyle = .normal,
        bevelSpan: CGFloat = RoxyBevelSpan.control
    ) -> some View {
        background(fill, in: RoxyRadius.shape(radius))
            .roxyEdge(radius: radius, style: edge, bevelSpan: bevelSpan)
    }

    func roxyRaisedShadow(_ palette: RoxyPalette) -> some View {
        let shadow = palette.raisedShadow
        return self.shadow(color: shadow.color, radius: shadow.radius, y: shadow.y)
    }

    func roxyFloatShadow(_ palette: RoxyPalette) -> some View {
        palette.floatShadows.reduce(AnyView(self)) { view, shadow in
            AnyView(view.shadow(color: shadow.color, radius: shadow.radius, y: shadow.y))
        }
    }
}

// MARK: - Motion

/// Ported from the desktop's motion tokens. The built-in curves are too weak to
/// feel intentional, so movement comes from this set, not `.easeInOut`.
enum RoxyMotion {
    /// Entrances: fast start, soft landing.
    static func outQuart(_ duration: TimeInterval = 0.15) -> Animation {
        .timingCurve(0.23, 1, 0.32, 1, duration: duration)
    }

    /// Movement of something already on screen.
    static func inOutQuart(_ duration: TimeInterval = 0.2) -> Animation {
        .timingCurve(0.77, 0, 0.175, 1, duration: duration)
    }

    /// Sheets and drawers.
    static func drawer(_ duration: TimeInterval = 0.3) -> Animation {
        .timingCurve(0.32, 0.72, 0, 1, duration: duration)
    }
}

/// Press feedback. The scale drops under Reduce Motion; the opacity stays,
/// since that is the part that aids comprehension rather than moves.
struct PressScaleButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(RoxyMotion.outQuart(0.14), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressScaleButtonStyle {
    static var pressScale: PressScaleButtonStyle { PressScaleButtonStyle() }
}

// MARK: - Theme

private struct RoxyPaletteKey: EnvironmentKey {
    static let defaultValue = RoxyPalette.dark
}

extension EnvironmentValues {
    /// Read from the environment, not a global, so a theme swap is one write at
    /// the root.
    var roxyPalette: RoxyPalette {
        get { self[RoxyPaletteKey.self] }
        set { self[RoxyPaletteKey.self] = newValue }
    }
}

/// Resolves the palette, paints the page, sets the default type and color.
struct RoxyTheme<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    /// Pin the theme instead of following the system. `nil` follows the system.
    var appearance: ColorScheme?

    @ViewBuilder var content: Content

    private var palette: RoxyPalette {
        .resolve(for: appearance ?? colorScheme)
    }

    var body: some View {
        content
            .environment(\.roxyPalette, palette)
            .font(RoxyFont.bodyLarge)
            .foregroundStyle(palette.text)
            .tint(palette.accent)
            .background(palette.bg.ignoresSafeArea())
            .preferredColorScheme(appearance)
    }
}
