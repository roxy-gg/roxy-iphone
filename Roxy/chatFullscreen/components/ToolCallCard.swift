//
//  ToolCallCard.swift
//  Roxy
//

import SwiftUI

/// The whole card is the tap target: once expanded, the header is the smallest
/// part of the thing you are trying to close.
struct ToolCallCard: View {
    @Environment(\.roxyPalette) private var palette

    let toolCall: ToolCallUiModel
    let onClick: () -> Void

    private var toolIcon: String {
        switch toolCall.type {
        case .file: "doc.text"
        case .terminal: "terminal"
        }
    }

    var body: some View {
        Button(action: onClick) {
            VStack(spacing: 0) {
                header

                if toolCall.isExpanded {
                    RoxyDivider()

                    Text(toolCall.detail)
                        .font(RoxyFont.bodySmallMono)
                        .roxyLineHeight(.bodySmall)
                        .foregroundStyle(palette.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressScale)
        .roxySurface(palette.surface2, radius: RoxyRadius.medium)
        .clipShape(RoxyRadius.shape(RoxyRadius.medium))
        .animation(RoxyMotion.outQuart(0.16), value: toolCall.isExpanded)
    }

    private var header: some View {
        HStack(spacing: 0) {
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(palette.textSubtle)
                .frame(width: 17, height: 17)
                .rotationEffect(.degrees(toolCall.isExpanded ? 90 : 0))
                .accessibilityLabel(
                    toolCall.isExpanded ? "Collapse tool call" : "Expand tool call"
                )

            Spacer().frame(width: 9)

            Image(systemName: toolIcon)
                .font(.system(size: 15))
                .foregroundStyle(palette.textMuted)
                .frame(width: 30, height: 30)
                .roxySurface(palette.elevated, radius: RoxyRadius.small)

            Spacer().frame(width: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(toolCall.name)
                    .font(RoxyFont.labelMedium)
                    .fontWeight(.semibold)
                    .foregroundStyle(palette.text)

                Text(toolCall.title)
                    .font(RoxyFont.bodySmallMono)
                    .foregroundStyle(palette.textMuted)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 8)

            statusIndicator
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
    }

    @ViewBuilder
    private var statusIndicator: some View {
        switch toolCall.status {
        case .complete:
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(palette.success)
                .frame(width: 16, height: 16)
                .accessibilityLabel("Complete")
        case .running:
            Circle()
                .fill(palette.accent)
                .frame(width: 7, height: 7)
                .accessibilityLabel("Running")
        }
    }
}

struct ToolCallStack: View {
    let toolCalls: [ToolCallUiModel]
    let onToolCallClick: (String) -> Void

    var body: some View {
        VStack(spacing: 8) {
            ForEach(toolCalls) { toolCall in
                ToolCallCard(toolCall: toolCall) {
                    onToolCallClick(toolCall.id)
                }
            }
        }
    }
}

#Preview {
    RoxyTheme {
        ToolCallStack(
            toolCalls: [
                ToolCallUiModel(
                    id: "tool-1",
                    type: .file,
                    name: "read",
                    title: "shared/theme.ts",
                    detail: "Read the desktop theme token definitions.",
                    status: .complete,
                    isExpanded: true
                ),
                ToolCallUiModel(
                    id: "tool-2",
                    type: .terminal,
                    name: "bash",
                    title: "./gradlew assembleDebug",
                    detail: "Build completed successfully.",
                    status: .running
                )
            ],
            onToolCallClick: { _ in }
        )
        .padding(20)
    }
}
