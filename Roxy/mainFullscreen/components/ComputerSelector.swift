//
//  ComputerSelector.swift
//  Roxy
//

import SwiftUI

/// The list opens inside the card, not above it. A popover was tried and
/// reverted: its own container drew a second, mismatched outline around this
/// component's hairline, and its beak has no counterpart in Compose.
///
/// The cost is that a tap outside no longer closes it — use the chevron or pick
/// a row, as an inline disclosure behaves on iOS.
struct ComputerSelector: View {
    @Environment(\.roxyPalette) private var palette

    let selectedComputer: ComputerUiModel
    let computers: [ComputerUiModel]
    let expanded: Bool
    let onExpandedChange: (Bool) -> Void
    let onComputerSelected: (String) -> Void
    var onAddNewComputer: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            Button {
                onExpandedChange(!expanded)
            } label: {
                anchor
            }
            .buttonStyle(.pressScale)

            if expanded {
                // A surface step above the anchor, matching the tonal gap the
                // Kotlin gets from an `elevated` menu over a `surface-2` anchor.
                VStack(spacing: 0) {
                    RoxyDivider()

                    ForEach(Array(computers.enumerated()), id: \.element.id) { index, computer in
                        Button {
                            onComputerSelected(computer.id)
                            onExpandedChange(false)
                        } label: {
                            menuItem(for: computer)
                        }
                        .buttonStyle(.pressScale)

                        if index != computers.count - 1 {
                            RoxyDivider()
                        }
                    }

                    if !computers.isEmpty {
                        RoxyDivider()
                    }

                    Button {
                        onAddNewComputer()
                        onExpandedChange(false)
                    } label: {
                        addNewComputerItem
                    }
                    .buttonStyle(.pressScale)
                }
                .background(palette.elevated)
            }
        }
        .roxySurface(
            palette.surface2,
            radius: RoxyRadius.large,
            edge: expanded ? .strong : .normal,
            bevelSpan: RoxyBevelSpan.panel
        )
        .clipShape(RoxyRadius.shape(RoxyRadius.large))
        .modifier(AnchorLift(isLifted: expanded))
        .animation(RoxyMotion.outQuart(0.18), value: expanded)
    }

    private var anchor: some View {
        HStack(spacing: 11) {
            Image(systemName: "desktopcomputer")
                .font(.system(size: 18))
                .foregroundStyle(palette.textMuted)
                .frame(width: 36, height: 36)
                .roxySurface(palette.elevated, radius: RoxyRadius.medium)

            VStack(alignment: .leading, spacing: 2) {
                Text(selectedComputer.name)
                    .font(RoxyFont.titleSmall)
                    .foregroundStyle(palette.text)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    ConnectionDot(isConnected: selectedComputer.isConnected)

                    Text(selectedComputer.status)
                        .font(RoxyFont.bodySmall)
                        .foregroundStyle(palette.textMuted)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.down")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(palette.textMuted)
                .frame(width: 20, height: 20)
                .rotationEffect(.degrees(expanded ? 180 : 0))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .contentShape(Rectangle())
        .accessibilityLabel(expanded ? "Collapse computers" : "Choose computer")
    }

    private func menuItem(for computer: ComputerUiModel) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "desktopcomputer")
                .font(.system(size: 18))
                .foregroundStyle(palette.textMuted)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 1) {
                Text(computer.name)
                    .font(RoxyFont.titleSmall)
                    .foregroundStyle(palette.text)
                    .lineLimit(1)

                Text(computer.status)
                    .font(RoxyFont.bodySmall)
                    .foregroundStyle(palette.textMuted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if computer.id == selectedComputer.id {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(palette.accent)
                    .accessibilityLabel("Selected")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private var addNewComputerItem: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(palette.textMuted)
                .frame(width: 22)

            Text("Add new computer")
                .font(RoxyFont.titleSmall)
                .foregroundStyle(palette.text)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .accessibilityLabel("Add new computer")
    }
}

/// Only present while the list is open.
private struct AnchorLift: ViewModifier {
    @Environment(\.roxyPalette) private var palette

    let isLifted: Bool

    func body(content: Content) -> some View {
        let shadow = palette.raisedShadow
        return content.shadow(
            color: isLifted ? shadow.color : .clear,
            radius: shadow.radius,
            y: isLifted ? shadow.y : 0
        )
    }
}

private struct ConnectionDot: View {
    @Environment(\.roxyPalette) private var palette

    let isConnected: Bool

    var body: some View {
        Circle()
            .fill(isConnected ? palette.success : palette.textSubtle)
            .frame(width: 7, height: 7)
    }
}

#Preview {
    RoxyTheme {
        VStack(spacing: 20) {
            ComputerSelector(
                selectedComputer: .none,
                computers: [],
                expanded: true,
                onExpandedChange: { _ in },
                onComputerSelected: { _ in }
            )

            ComputerSelector(
                selectedComputer: ComputerUiModel(id: "1", name: "Desktop PC", status: "Connected", isConnected: true),
                computers: [
                    ComputerUiModel(id: "1", name: "Desktop PC", status: "Connected", isConnected: true),
                    ComputerUiModel(id: "2", name: "Studio", status: "Last seen 4m ago", isConnected: false)
                ],
                expanded: true,
                onExpandedChange: { _ in },
                onComputerSelected: { _ in }
            )
        }
        .padding(20)
    }
}
