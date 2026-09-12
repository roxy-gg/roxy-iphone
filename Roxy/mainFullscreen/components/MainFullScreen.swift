//
//  MainFullScreen.swift
//  Roxy
//

import SwiftUI

enum ProjectSortOrder: String, CaseIterable, Identifiable {
    case recent
    case alphabetical
    case sessions

    var id: String { rawValue }

    var label: String {
        switch self {
        case .recent: "Recent activity"
        case .alphabetical: "Name (A-Z)"
        case .sessions: "Most sessions"
        }
    }
}

/// Takes the whole UiState and a set of callbacks. The sort order and whether
/// settings are open are the exceptions — local, since neither belongs to the
/// session nor survives leaving the screen.
struct MainFullScreen: View {
    @Environment(\.roxyPalette) private var palette

    let uiState: MainFullScreenUiState
    let onComputerMenuExpandedChange: (Bool) -> Void
    let onComputerSelected: (String) -> Void
    let onSessionSelected: (String) -> Void
    var onAddNewComputer: () -> Void = {}
    var onScanQrCode: () -> Void = {}
    var onDismissConnectDialog: () -> Void = {}
    var onConnectComputer: (String, String) -> Void = { _, _ in }
    var onDisconnectComputer: () -> Void = {}
    var initialToken: String = ""
    var initialPin: String = ""

    @State private var isSettingsOpen = false
    @State private var sortOrder: ProjectSortOrder = .recent
    @State private var isSortMenuExpanded = false

    private static let contentMaxWidth: CGFloat = 720

    private var sortedProjects: [ProjectUiModel] {
        switch sortOrder {
        // `.recent` is the desktop's own order, not a sort — it knows what was
        // touched last, and this screen does not.
        case .recent: uiState.projects
        case .alphabetical: uiState.projects.sorted { $0.name.lowercased() < $1.name.lowercased() }
        case .sessions: uiState.projects.sorted { $0.sessions.count > $1.sessions.count }
        }
    }

    var body: some View {
        ZStack {
            palette.bg.ignoresSafeArea()

            Group {
                if isSettingsOpen {
                    SettingsView(
                        selectedComputer: uiState.selectedComputer,
                        onConnectClick: {
                            isSettingsOpen = false
                            onAddNewComputer()
                        },
                        onScanQrClick: {
                            isSettingsOpen = false
                            onScanQrCode()
                        },
                        onDisconnectClick: onDisconnectComputer,
                        onBackClick: { isSettingsOpen = false }
                    )
                    .transition(.opacity)
                } else {
                    sessionList
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: Self.contentMaxWidth)
            .frame(maxWidth: .infinity)
            .animation(RoxyMotion.outQuart(0.2), value: isSettingsOpen)

            if uiState.isConnectingDialogVisible {
                ConnectComputerDialog(
                    isConnecting: uiState.isConnecting,
                    errorMessage: uiState.connectionError,
                    onDismiss: onDismissConnectDialog,
                    onConnect: onConnectComputer,
                    onScanQrCode: onScanQrCode,
                    qrFeedbackMessage: uiState.qrFeedbackMessage,
                    initialTokenOrUrl: uiState.prefilledToken.isEmpty ? initialToken : uiState.prefilledToken,
                    initialPin: uiState.prefilledPin.isEmpty ? initialPin : uiState.prefilledPin
                )
            }
        }
        .animation(RoxyMotion.outQuart(0.18), value: uiState.isConnectingDialogVisible)
    }

    private var sessionList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                header

                VStack(alignment: .leading, spacing: 6) {
                    SectionLabel("CONNECTED COMPUTER")
                        .padding(.leading, 2)

                    ComputerSelector(
                        selectedComputer: uiState.selectedComputer,
                        computers: uiState.computers,
                        expanded: uiState.isComputerMenuExpanded,
                        onExpandedChange: onComputerMenuExpandedChange,
                        onComputerSelected: onComputerSelected,
                        onAddNewComputer: onAddNewComputer
                    )
                }

                projectsHeader

                if sortedProjects.isEmpty {
                    EmptyProjectsState(
                        isConnected: uiState.selectedComputer.isConnected,
                        onConnectClick: onAddNewComputer
                    )
                    .padding(.top, 12)
                } else {
                    ForEach(sortedProjects) { project in
                        ProjectSection(
                            project: project,
                            onSessionSelected: onSessionSelected
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 36)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            HStack(spacing: 13) {
                Image("RoxyAvatar")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 46, height: 46)
                    .clipShape(RoxyRadius.shape(13))
                    .overlay(RoxyRadius.shape(13).strokeBorder(palette.edgeStrong, lineWidth: 1))
                    .accessibilityLabel("Roxy Logo")

                VStack(alignment: .leading, spacing: 2) {
                    Text("Roxy")
                        .font(RoxyFont.headlineSmall)
                        .foregroundStyle(palette.text)

                    Text("Remote Workspace")
                        .font(RoxyFont.bodySmall)
                        .foregroundStyle(palette.textMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                isSettingsOpen = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18))
                    .foregroundStyle(palette.textMuted)
                    .frame(width: 42, height: 42)
                    .background(palette.surface2, in: Circle())
                    .overlay(Circle().strokeBorder(palette.edgeStrong, lineWidth: 1))
            }
            .buttonStyle(.pressScale)
            .accessibilityLabel("Settings")
        }
    }

    private var projectsHeader: some View {
        HStack {
            SectionLabel("PROJECTS")

            Spacer(minLength: 8)

            Menu {
                Picker("Sort projects", selection: $sortOrder) {
                    ForEach(ProjectSortOrder.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.inline)
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 15))
                    // Tinted off the default, so an unexpected order says so.
                    .foregroundStyle(sortOrder != .recent ? palette.text : palette.textSubtle)
                    .frame(width: 28, height: 28)
                    .background(
                        isSortMenuExpanded ? palette.surface2 : .clear,
                        in: RoxyRadius.shape(6)
                    )
            }
            .buttonStyle(.pressScale)
            .accessibilityLabel("Sort projects")
        }
        .padding(.top, 6)
        .padding(.horizontal, 2)
    }
}

struct SectionLabel: View {
    @Environment(\.roxyPalette) private var palette

    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(RoxyFont.labelSmallMono)
            .fontWeight(.semibold)
            .tracking(1.2)
            .foregroundStyle(palette.textSubtle)
    }
}

/// Two cases — nothing paired, or nothing running. They need different words and
/// only one has an action, so they share a card rather than a message.
private struct EmptyProjectsState: View {
    @Environment(\.roxyPalette) private var palette

    let isConnected: Bool
    let onConnectClick: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: isConnected ? "folder" : "desktopcomputer")
                .font(.system(size: 20))
                .foregroundStyle(isConnected ? palette.textMuted : palette.accent)
                .frame(width: 44, height: 44)
                .background(palette.elevated, in: Circle())
                .overlay(Circle().strokeBorder(palette.edgeStrong, lineWidth: 1))

            VStack(spacing: 4) {
                Text(isConnected ? "No active sessions" : "No computer connected")
                    .font(RoxyFont.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundStyle(palette.text)
                    .multilineTextAlignment(.center)

                Text(
                    isConnected
                        ? "Open a project or run a session in Roxy Desktop to see it here."
                        : "Connect your PC to sync projects and control your sessions remotely."
                )
                .font(RoxyFont.bodySmall)
                .roxyLineHeight(.bodySmall)
                .foregroundStyle(palette.textMuted)
                .multilineTextAlignment(.center)
            }

            if !isConnected {
                Spacer().frame(height: 4)

                Button(action: onConnectClick) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))

                        Text("Connect PC")
                            .font(RoxyFont.labelLarge)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(palette.bg)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(palette.accent, in: RoxyRadius.shape(10))
                }
                .buttonStyle(.pressScale)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 32)
        .roxySurface(palette.surface2, radius: RoxyRadius.large, bevelSpan: RoxyBevelSpan.panel)
    }
}

// MARK: - Previews

private let mainPreviewState = MainFullScreenUiState(
    selectedComputer: ComputerUiModel(id: "pc-remote", name: "Desktop PC", status: "Connected", isConnected: true),
    computers: [ComputerUiModel(id: "pc-remote", name: "Desktop PC", status: "Connected", isConnected: true)],
    projects: []
)

#Preview("Main - Dark") {
    RoxyTheme(appearance: .dark) {
        MainFullScreen(
            uiState: mainPreviewState,
            onComputerMenuExpandedChange: { _ in },
            onComputerSelected: { _ in },
            onSessionSelected: { _ in }
        )
    }
}

#Preview("Main - Light") {
    RoxyTheme(appearance: .light) {
        MainFullScreen(
            uiState: mainPreviewState,
            onComputerMenuExpandedChange: { _ in },
            onComputerSelected: { _ in },
            onSessionSelected: { _ in }
        )
    }
}
