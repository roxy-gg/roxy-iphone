//
//  RoxyAppViewModel.swift
//  Roxy
//

import Foundation

enum RoxyDestination: Equatable {
    case main
    case chat
}

struct RoxyAppUiState: Equatable {
    var destination: RoxyDestination
    var main: MainFullScreenUiState
    var chat: ChatFullScreenUiState
}

/// The whole app's state. One view model rather than one per screen: the
/// connection decides what either can show, and both feed off one stream.
///
/// The transport is NOT wired up yet — `shared/data` is empty until the
/// `Remote*` layer is ported. So the methods that would talk to the desktop
/// (`connectRemote`, and the streaming side of the chat) only move local state,
/// and the app starts and stays disconnected. Everything above this line —
/// destination, the composer, tool-call expansion, the pairing dialog — is
/// already the real behaviour.
@MainActor
@Observable
final class RoxyAppViewModel {
    private(set) var uiState: RoxyAppUiState

    private var activeSessionId: String?

    init() {
        uiState = Self.initialUiState()
    }

    // MARK: - Pairing

    func showConnectDialog(prefilledToken: String? = nil, prefilledPin: String? = nil) {
        uiState.main.isConnectingDialogVisible = true
        uiState.main.isComputerMenuExpanded = false
        uiState.main.connectionError = nil
        uiState.main.prefilledToken = prefilledToken ?? ""
        uiState.main.prefilledPin = prefilledPin ?? ""
        uiState.main.qrFeedbackMessage = nil
    }

    func dismissConnectDialog() {
        uiState.main.isConnectingDialogVisible = false
        uiState.main.isConnecting = false
        uiState.main.connectionError = nil
        uiState.main.qrFeedbackMessage = nil
    }

    /// A scanned code and a deep link arrive as the same string, so they take
    /// the same path. Parsing it needs `RemoteWorkspaceUtils`, so for now the
    /// dialog just opens with the raw text in the token field.
    func onQrCodeScanned(_ scannedText: String) {
        let text = scannedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            uiState.main.isConnectingDialogVisible = true
            uiState.main.connectionError = "Invalid QR code: no Roxy connection token found."
            uiState.main.qrFeedbackMessage = nil
            return
        }

        uiState.main.isConnectingDialogVisible = true
        uiState.main.prefilledToken = text
        uiState.main.prefilledPin = ""
        uiState.main.connectionError = nil
        uiState.main.qrFeedbackMessage = "QR code scanned! Enter the 6-digit PIN shown on your PC."
    }

    func onScanError(_ errorMessage: String) {
        uiState.main.connectionError = "QR Scanner error: \(errorMessage)"
    }

    func connectRemote(tokenOrUrl: String, pin: String) {
        uiState.main.connectionError = "No transport on this build yet. The remote layer has not been ported."
    }

    func disconnectRemote() {
        activeSessionId = nil
        uiState.destination = .main
        uiState.main.selectedComputer = .none
        uiState.main.computers = []
        uiState.main.projects = []
        uiState.main.isConnecting = false
        uiState.main.connectionError = nil
        clearChat()
    }

    // MARK: - Main screen

    func setComputerMenuExpanded(_ expanded: Bool) {
        uiState.main.isComputerMenuExpanded = expanded
    }

    func selectComputer(_ computerId: String) {
        guard let computer = uiState.main.computers.first(where: { $0.id == computerId }) else { return }
        uiState.main.selectedComputer = computer
        uiState.main.isComputerMenuExpanded = false
    }

    func openSession(_ sessionId: String) {
        activeSessionId = sessionId

        guard let project = uiState.main.projects.first(where: { project in
            project.sessions.contains { $0.id == sessionId }
        }), let session = project.sessions.first(where: { $0.id == sessionId }) else { return }

        uiState.main.projects = uiState.main.projects.map { candidate in
            ProjectUiModel(
                id: candidate.id,
                name: candidate.name,
                sessions: candidate.sessions.map { item in
                    var updated = item
                    updated.isActive = item.id == sessionId
                    return updated
                }
            )
        }
        uiState.main.isComputerMenuExpanded = false

        uiState.chat.sessionTitle = session.title
        uiState.chat.projectName = project.name
        uiState.chat.composerText = ""
        uiState.chat.messages = []
        uiState.chat.toolCalls = []
        uiState.chat.isRunning = false
        uiState.chat.isSyncing = false

        uiState.destination = .chat
    }

    func showMainScreen() {
        uiState.destination = .main
    }

    // MARK: - Chat

    func updateComposer(_ text: String) {
        uiState.chat.composerText = text
    }

    func submitComposer() {
        let currentText = uiState.chat.composerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !currentText.isEmpty else { return }

        // Shown before the desktop confirms: the input must feel instant. With
        // no transport there is nothing to confirm it, so the turn just sits.
        uiState.chat.composerText = ""
        uiState.chat.messages.append(
            ChatMessageUiModel(id: UUID().uuidString, text: currentText, isUser: true)
        )
    }

    func toggleToolCall(_ toolCallId: String) {
        // The card does not know which list it came from, so reach both.
        for index in uiState.chat.messages.indices where !uiState.chat.messages[index].isUser {
            uiState.chat.messages[index].parts = uiState.chat.messages[index].parts.map { part in
                guard case .tool(var tool) = part, tool.id == toolCallId else { return part }
                tool.isExpanded.toggle()
                return .tool(tool)
            }
        }
        uiState.chat.toolCalls = uiState.chat.toolCalls.map { toolCall in
            guard toolCall.id == toolCallId else { return toolCall }
            var updated = toolCall
            updated.isExpanded.toggle()
            return updated
        }
    }

    func getInitialToken() -> String { "" }
    func getInitialPin() -> String { "" }

    // MARK: - Helpers

    private func clearChat() {
        uiState.chat.sessionTitle = ""
        uiState.chat.projectName = ""
        uiState.chat.messages = []
        uiState.chat.toolCalls = []
        uiState.chat.isSyncing = false
    }

    private static func initialUiState() -> RoxyAppUiState {
        RoxyAppUiState(
            destination: .main,
            main: MainFullScreenUiState(
                selectedComputer: .none,
                computers: [],
                projects: []
            ),
            chat: ChatFullScreenUiState(
                sessionTitle: "",
                projectName: "",
                messages: [],
                toolCalls: [],
                isSyncing: false
            )
        )
    }
}

extension ComputerUiModel {
    /// Shown before pairing and after disconnecting.
    static let none = ComputerUiModel(
        id: "none",
        name: "No computer connected",
        status: "Disconnected",
        isConnected: false
    )
}
