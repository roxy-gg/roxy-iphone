//
//  ChatFullScreen.swift
//  Roxy
//

import SwiftUI

/// Takes the whole UiState and a set of callbacks, owns no state itself.
struct ChatFullScreen: View {
    @Environment(\.roxyPalette) private var palette

    let uiState: ChatFullScreenUiState
    let onBackClick: () -> Void
    let onComposerChange: (String) -> Void
    let onComposerSubmit: () -> Void
    let onToolCallClick: (String) -> Void

    /// Long measures are hard to track back to the next line, and iPad and Mac
    /// give this screen far more width than it should use.
    private static let contentMaxWidth: CGFloat = 720

    private var isEmpty: Bool {
        uiState.messages.isEmpty && uiState.toolCalls.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            ChatHeader(
                sessionTitle: uiState.sessionTitle,
                projectName: uiState.projectName,
                isRunning: uiState.isRunning,
                isSyncing: uiState.isSyncing,
                onBackClick: onBackClick
            )

            RoxyDivider()

            transcript

            composer
        }
        .background(palette.bg)
    }

    private var transcript: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                if uiState.isSyncing && isEmpty {
                    syncingIndicator
                } else if isEmpty {
                    emptySession
                } else {
                    ForEach(uiState.messages) { message in
                        if message.isUser {
                            userMessage(message)
                        } else {
                            assistantMessage(message)
                        }
                    }

                    // Reported before being attached to a part; without this
                    // they never appear, which reads as the agent idling.
                    if !orphanToolCalls.isEmpty {
                        ToolCallStack(
                            toolCalls: orphanToolCalls,
                            onToolCallClick: onToolCallClick
                        )
                    }
                }
            }
            .frame(maxWidth: Self.contentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.top, 28)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var orphanToolCalls: [ToolCallUiModel] {
        let attached = Set(
            uiState.messages
                .flatMap(\.parts)
                .compactMap { part -> String? in
                    if case .tool(let tool) = part { return tool.id }
                    return nil
                }
        )
        return uiState.toolCalls.filter { !attached.contains($0.id) }
    }

    private var syncingIndicator: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(palette.accent)
                .frame(width: 28, height: 28)

            Text("Syncing with desktop...")
                .font(RoxyFont.bodyMedium)
                .foregroundStyle(palette.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
    }

    private var emptySession: some View {
        Text("No messages yet. Send a prompt to get started.")
            .font(RoxyFont.bodyMedium)
            .foregroundStyle(palette.textMuted)
            .frame(maxWidth: .infinity)
            .padding(.top, 48)
    }

    /// The only bubble on the screen: short, yours, and pinned right so you can
    /// find your own prompts while scrolling back.
    private func userMessage(_ message: ChatMessageUiModel) -> some View {
        HStack {
            Spacer(minLength: 40)

            Text(message.text)
                .font(RoxyFont.bodyLarge)
                .roxyLineHeight(.bodyLarge)
                .foregroundStyle(palette.text)
                .textSelection(.enabled)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .roxySurface(palette.surface2, radius: RoxyRadius.large)
        }
    }

    /// An assistant turn is its parts, walked in the order they arrived.
    @ViewBuilder
    private func assistantMessage(_ message: ChatMessageUiModel) -> some View {
        if !message.parts.isEmpty {
            ForEach(message.parts) { part in
                switch part {
                case .text(let textPart):
                    MarkdownText(markdown: textPart.text)

                case .reasoning(let reasoning):
                    ReasoningCard(reasoning: reasoning)

                case .tool(let tool):
                    ToolCallCard(toolCall: tool) {
                        onToolCallClick(tool.id)
                    }
                }
            }
        } else if !message.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            MarkdownText(markdown: message.text)
        }
    }

    private var composer: some View {
        ChatComposer(
            text: uiState.composerText,
            onTextChange: onComposerChange,
            onSubmit: onComposerSubmit
        )
        .frame(maxWidth: Self.contentMaxWidth)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(palette.bg)
    }
}

struct ChatHeader: View {
    @Environment(\.roxyPalette) private var palette

    let sessionTitle: String
    let projectName: String
    var isRunning: Bool = false
    var isSyncing: Bool = false
    let onBackClick: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onBackClick) {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(palette.textMuted)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.pressScale)
            .accessibilityLabel("Back to sessions")

            Spacer().frame(width: 4)

            VStack(alignment: .leading, spacing: 1) {
                Text(sessionTitle)
                    .font(RoxyFont.titleSmall)
                    .fontWeight(.semibold)
                    .foregroundStyle(palette.text)
                    .lineLimit(1)
                    .truncationMode(.tail)

                HStack(spacing: 5) {
                    Image(systemName: "folder")
                        .font(.system(size: 9))
                        .foregroundStyle(palette.textSubtle)

                    Text(projectName)
                        .font(RoxyFont.labelSmall)
                        .foregroundStyle(palette.textMuted)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            status
        }
        .padding(.leading, 6)
        .padding(.trailing, 16)
        .padding(.vertical, 5)
    }

    /// Falls back to the app's name so the corner is never empty.
    @ViewBuilder
    private var status: some View {
        if isRunning {
            statusLabel("Thinking...", color: palette.accent)
        } else if isSyncing {
            statusLabel("Syncing...", color: palette.textSubtle)
        } else {
            Text("Roxy")
                .font(RoxyFont.labelMedium)
                .foregroundStyle(palette.textSubtle)
        }
    }

    private func statusLabel(_ text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(text)
                .font(RoxyFont.labelSmall)
                .foregroundStyle(color)
        }
    }
}

// MARK: - Previews

private let chatPreviewState = ChatFullScreenUiState(
    sessionTitle: "Remote Session",
    projectName: "roxy-android",
    messages: [],
    toolCalls: []
)

#Preview("Chat - Dark") {
    RoxyTheme(appearance: .dark) {
        ChatFullScreen(
            uiState: chatPreviewState,
            onBackClick: {},
            onComposerChange: { _ in },
            onComposerSubmit: {},
            onToolCallClick: { _ in }
        )
    }
}

#Preview("Chat - Light") {
    RoxyTheme(appearance: .light) {
        ChatFullScreen(
            uiState: chatPreviewState,
            onBackClick: {},
            onComposerChange: { _ in },
            onComposerSubmit: {},
            onToolCallClick: { _ in }
        )
    }
}
