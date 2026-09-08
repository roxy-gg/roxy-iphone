//
//  SettingsView.swift
//  Roxy
//

import SwiftUI

private struct SettingsItemUi: Identifiable {
    let title: String
    let subtitle: String
    var isDestructive: Bool = false
    var onClick: () -> Void = {}

    var id: String { title }
}

/// Shown in place of the session list, not pushed over it.
struct SettingsView: View {
    @Environment(\.roxyPalette) private var palette

    let selectedComputer: ComputerUiModel
    let onConnectClick: () -> Void
    var onScanQrClick: () -> Void = {}
    var onDisconnectClick: () -> Void = {}
    let onBackClick: () -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                header

                SettingsCategorySection(title: "Connection", items: connectionItems)

                SettingsCategorySection(
                    title: "About",
                    items: [
                        SettingsItemUi(title: "Roxy iOS", subtitle: "v0.1.0"),
                        SettingsItemUi(
                            title: "Desktop Sync",
                            subtitle: selectedComputer.isConnected
                                ? "\(selectedComputer.name) • Connected"
                                : "Not paired"
                        )
                    ]
                )
            }
            .padding(.leading, 16)
            .padding(.top, 16)
            .padding(.trailing, 20)
            .padding(.bottom, 36)
        }
    }

    private var header: some View {
        HStack(spacing: 0) {
            Button(action: onBackClick) {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(palette.textMuted)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.pressScale)
            .accessibilityLabel("Back to main")

            Spacer().frame(width: 4)

            Text("Settings")
                .font(RoxyFont.headlineSmall)
                .foregroundStyle(palette.text)
        }
    }

    private var connectionItems: [SettingsItemUi] {
        var items: [SettingsItemUi] = [
            SettingsItemUi(
                title: "Scan Desktop QR",
                subtitle: "Pair quickly by scanning PC screen",
                onClick: onScanQrClick
            ),
            SettingsItemUi(
                title: "Remote Workspace",
                subtitle: selectedComputer.isConnected
                    ? "Connected: \(selectedComputer.name)"
                    : "Disconnected (Tap to enter PIN/link)",
                onClick: onConnectClick
            ),
            SettingsItemUi(title: "Relay Service", subtitle: "roxy.gg/api/remote")
        ]

        if selectedComputer.isConnected {
            items.append(
                SettingsItemUi(
                    title: "Disconnect PC",
                    subtitle: "Disconnect from \(selectedComputer.name)",
                    isDestructive: true,
                    onClick: onDisconnectClick
                )
            )
        }

        return items
    }
}

private struct SettingsCategorySection: View {
    @Environment(\.roxyPalette) private var palette

    let title: String
    let items: [SettingsItemUi]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(RoxyFont.labelMedium)
                .fontWeight(.semibold)
                .foregroundStyle(palette.textMuted)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    Button(action: item.onClick) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(RoxyFont.titleSmall)
                                // `accent`, not `danger`, matching the Kotlin —
                                // so disconnecting reads as a highlight, not a
                                // warning. Worth a second look over there.
                                .foregroundStyle(item.isDestructive ? palette.accent : palette.text)

                            Text(item.subtitle)
                                .font(RoxyFont.bodySmall)
                                .foregroundStyle(palette.textMuted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.pressScale)

                    if index != items.count - 1 {
                        RoxyDivider()
                            .padding(.leading, 16)
                    }
                }
            }
            .roxySurface(palette.surface, radius: RoxyRadius.large, bevelSpan: RoxyBevelSpan.panel)
            .clipShape(RoxyRadius.shape(RoxyRadius.large))
        }
    }
}

#Preview {
    RoxyTheme {
        SettingsView(
            selectedComputer: ComputerUiModel(id: "pc", name: "Desktop PC", status: "Connected", isConnected: true),
            onConnectClick: {},
            onBackClick: {}
        )
    }
}
