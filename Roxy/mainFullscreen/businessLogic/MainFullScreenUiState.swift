//
//  MainFullScreenUiState.swift
//  Roxy
//

import Foundation

struct ComputerUiModel: Identifiable, Equatable {
    let id: String
    let name: String
    /// Already formatted — "Connected", "Last seen 4m ago".
    let status: String
    let isConnected: Bool
}

struct SessionUiModel: Identifiable, Equatable {
    let id: String
    let title: String
    let summary: String
    /// Already formatted — "Now", "18m", "Yesterday".
    let updatedAt: String
    var isActive: Bool = false
}

struct ProjectUiModel: Identifiable, Equatable {
    let id: String
    let name: String
    let sessions: [SessionUiModel]
}

struct MainFullScreenUiState: Equatable {
    var selectedComputer: ComputerUiModel
    var computers: [ComputerUiModel]
    var projects: [ProjectUiModel]
    var isComputerMenuExpanded: Bool = false

    // Pairing.
    var isConnectingDialogVisible: Bool = false
    var isConnecting: Bool = false
    var connectionError: String?
    var qrFeedbackMessage: String?
    /// Filled in by a scan, so the dialog opens ready.
    var prefilledToken: String = ""
    var prefilledPin: String = ""
}
