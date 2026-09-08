//
//  RoxyApp.swift
//  Roxy
//
//  Created by Fernando Rocha on 03/09/26.
//

import SwiftUI

/// `MainActivity`'s counterpart: owns the view model and the scanner, and turns
/// a deep link into a scanned pairing code.
@main
struct RoxyApp: App {
    @State private var viewModel = RoxyAppViewModel()

    var body: some Scene {
        WindowGroup {
            RoxyTheme {
                RoxyRootView(
                    uiState: viewModel.uiState,
                    onComputerMenuExpandedChange: viewModel.setComputerMenuExpanded,
                    onComputerSelected: viewModel.selectComputer,
                    onSessionSelected: viewModel.openSession,
                    onBackFromChat: viewModel.showMainScreen,
                    onComposerChange: viewModel.updateComposer,
                    onComposerSubmit: viewModel.submitComposer,
                    onToolCallClick: viewModel.toggleToolCall,
                    // Wrapped, not referenced: Swift cannot pass a method with
                    // default parameters as a `() -> Void`.
                    onAddNewComputer: { viewModel.showConnectDialog() },
                    onScanQrCode: startQrScanner,
                    onDismissConnectDialog: viewModel.dismissConnectDialog,
                    onConnectComputer: viewModel.connectRemote,
                    onDisconnectComputer: viewModel.disconnectRemote,
                    initialToken: viewModel.getInitialToken(),
                    initialPin: viewModel.getInitialPin()
                )
            }
            // `onOpenURL` covers cold and warm launches alike, so this is one
            // path where `MainActivity` needs two.
            .onOpenURL { url in
                viewModel.onQrCodeScanned(url.absoluteString)
            }
        }
    }

    /// `MainActivity` owns a `RemoteQrScanner` here. There is none yet, so the
    /// button reports why instead of doing nothing.
    private func startQrScanner() {
        viewModel.onScanError("QR scanning is not available on this build yet.")
    }
}
