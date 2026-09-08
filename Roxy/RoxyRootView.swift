//
//  RoxyRootView.swift
//  Roxy
//

import SwiftUI

/// `RoxyApp.kt`'s counterpart. The swap is deliberately UNANIMATED, matching the
/// Kotlin's bare `when` — unusual on iOS, so worth a decision rather than a
/// default; animating only here would make the two clients feel different.
struct RoxyRootView: View {
    let uiState: RoxyAppUiState
    let onComputerMenuExpandedChange: (Bool) -> Void
    let onComputerSelected: (String) -> Void
    let onSessionSelected: (String) -> Void
    let onBackFromChat: () -> Void
    let onComposerChange: (String) -> Void
    let onComposerSubmit: () -> Void
    let onToolCallClick: (String) -> Void
    let onAddNewComputer: () -> Void
    let onScanQrCode: () -> Void
    let onDismissConnectDialog: () -> Void
    let onConnectComputer: (String, String) -> Void
    let onDisconnectComputer: () -> Void
    let initialToken: String
    let initialPin: String

    var body: some View {
        switch uiState.destination {
        case .main:
            MainFullScreen(
                uiState: uiState.main,
                onComputerMenuExpandedChange: onComputerMenuExpandedChange,
                onComputerSelected: onComputerSelected,
                onSessionSelected: onSessionSelected,
                onAddNewComputer: onAddNewComputer,
                onScanQrCode: onScanQrCode,
                onDismissConnectDialog: onDismissConnectDialog,
                onConnectComputer: onConnectComputer,
                onDisconnectComputer: onDisconnectComputer,
                initialToken: initialToken,
                initialPin: initialPin
            )

        case .chat:
            ChatFullScreen(
                uiState: uiState.chat,
                onBackClick: onBackFromChat,
                onComposerChange: onComposerChange,
                onComposerSubmit: onComposerSubmit,
                onToolCallClick: onToolCallClick
            )
        }
    }
}
