//
//  ChatFullScreenUiState.swift
//  Roxy
//

import Foundation

enum ToolCallType: Equatable {
    case file
    case terminal
}

enum ToolCallStatus: Equatable {
    case complete
    case running
}

struct ToolCallUiModel: Identifiable, Equatable {
    let id: String
    let type: ToolCallType
    /// The tool that ran — `read`, `bash`.
    let name: String
    /// What it ran against — a path, a command.
    let title: String
    /// Grows while the tool runs, hence `var` where the Kotlin has `val` + copy.
    var detail: String
    var status: ToolCallStatus
    var isExpanded: Bool = false
}

struct TextPartUiModel: Identifiable, Equatable {
    let id: String
    let text: String
}

struct ReasoningUiModel: Identifiable, Equatable {
    let id: String
    let text: String
    var isExpanded: Bool = false
}

/// One piece of an assistant turn. A turn is a sequence of these because the
/// order is what makes it readable — think, run a tool, write, run another.
///
/// The sealed interface's nested classes become structs so a component can take
/// just the part it draws (`ReasoningCard` takes a `Reasoning`).
enum ChatPartUiModel: Identifiable, Equatable {
    case text(TextPartUiModel)
    case reasoning(ReasoningUiModel)
    case tool(ToolCallUiModel)

    var id: String {
        switch self {
        case .text(let part): part.id
        case .reasoning(let part): part.id
        case .tool(let tool): tool.id
        }
    }
}

struct ChatMessageUiModel: Identifiable, Equatable {
    let id: String
    /// A user turn's content, and the fallback for an assistant turn with no
    /// parts yet.
    var text: String = ""
    var isUser: Bool = false
    var parts: [ChatPartUiModel] = []
}

struct ChatFullScreenUiState: Equatable {
    var sessionTitle: String
    var projectName: String
    var messages: [ChatMessageUiModel]
    /// Not yet attached to a message part — see the orphan handling in the view.
    var toolCalls: [ToolCallUiModel] = []
    var composerText: String = ""
    /// The agent is working on the desktop.
    var isRunning: Bool = false
    /// This device is catching up with the desktop's transcript.
    var isSyncing: Bool = false
}
