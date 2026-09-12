//
//  ChatComposer.swift
//  Roxy
//

import SwiftUI

enum ModelProvider: Equatable {
    case anthropic
    case google
}

struct RoxyModelItem: Identifiable, Equatable {
    let id: String
    let provider: ModelProvider
    let section: String
    var hasReasoning: Bool = true
    var hasTools: Bool = true
    var isPinned: Bool = true

    /// The same model appears in several sections, so the id alone collides.
    var rowKey: String { "\(section)_\(id)" }
}

/// Hardcoded on both clients until the desktop reports what a machine has.
let desktopRoxyModels: [RoxyModelItem] = [
    // PINNED
    RoxyModelItem(id: "claude-sonnet-4-6", provider: .anthropic, section: "PINNED"),
    RoxyModelItem(id: "gemini-pro-agent", provider: .google, section: "PINNED"),
    RoxyModelItem(id: "claude-opus-4-6-thinking", provider: .anthropic, section: "PINNED"),
    RoxyModelItem(id: "claude-opus-5", provider: .anthropic, section: "PINNED"),
    RoxyModelItem(id: "claude-sonnet-5", provider: .anthropic, section: "PINNED"),
    RoxyModelItem(id: "gemini-3.1-pro-low", provider: .google, section: "PINNED"),
    RoxyModelItem(id: "gemini-3.8-flash-high", provider: .google, section: "PINNED"),

    // LATEST - CLAUDE (SUBSCRIPTION)
    RoxyModelItem(id: "claude-sonnet-4-6", provider: .anthropic, section: "LATEST - CLAUDE (SUBSCRIPTION)", isPinned: false),

    // CLAUDE (SUBSCRIPTION)
    RoxyModelItem(id: "claude-opus-5", provider: .anthropic, section: "CLAUDE (SUBSCRIPTION)", isPinned: true)
]

/// The text and the submit are hoisted; the model choice is not, because the
/// desktop does not accept one yet.
struct ChatComposer: View {
    @Environment(\.roxyPalette) private var palette

    let text: String
    let onTextChange: (String) -> Void
    let onSubmit: () -> Void
    var initialModel: String = "gemini-3.8-flash-high"

    @State private var currentModel: String
    @State private var showModelSheet = false

    init(
        text: String,
        onTextChange: @escaping (String) -> Void,
        onSubmit: @escaping () -> Void,
        initialModel: String = "gemini-3.8-flash-high"
    ) {
        self.text = text
        self.onTextChange = onTextChange
        self.onSubmit = onSubmit
        self.initialModel = initialModel
        _currentModel = State(initialValue: initialModel)
    }

    private var isSendActive: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            field
            toolbar
        }
        .padding(.leading, 14)
        .padding(.top, 11)
        .padding(.trailing, 12)
        .padding(.bottom, 10)
        // `strong` at rest, not on focus: the composer is always waiting for
        // input, so it reads live rather than lighting up once you commit.
        .roxySurface(
            palette.surface2,
            radius: RoxyRadius.extraLarge,
            edge: .strong,
            bevelSpan: RoxyBevelSpan.panel
        )
        .roxyFloatShadow(palette)
        .sheet(isPresented: $showModelSheet) {
            ModelSelectorSheet(
                selectedModel: currentModel,
                onModelSelected: { modelId in
                    currentModel = modelId
                    showModelSheet = false
                }
            )
        }
    }

    private var field: some View {
        TextField(
            "",
            text: Binding(get: { text }, set: onTextChange),
            prompt: Text("Ask Roxy anything... (paste or drop images)")
                .foregroundStyle(palette.textMuted),
            axis: .vertical
        )
        .textFieldStyle(.plain)
        .font(RoxyFont.bodyMedium)
        .foregroundStyle(palette.text)
        .tint(palette.accent)
        .lineLimit(1...5)
        .submitLabel(.send)
        .onSubmit {
            if isSendActive { onSubmit() }
        }
        .padding(.vertical, 4)
        .frame(minHeight: 36, alignment: .bottom)
        .accessibilityLabel("Message Roxy")
    }

    private var toolbar: some View {
        HStack(spacing: 0) {
            Button {
                // Attachments land here once the picker exists.
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(palette.textMuted)
                    .frame(width: 30, height: 30)
                    .background(palette.elevated, in: Circle())
                    .overlay(Circle().strokeBorder(palette.edge, lineWidth: 1))
            }
            .buttonStyle(.pressScale)
            .accessibilityLabel("Attach image or file")

            Spacer().frame(width: 8)

            modelPill

            Spacer(minLength: 8)

            sendButton
        }
    }

    private var modelPill: some View {
        Button {
            showModelSheet = true
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11))
                    .foregroundStyle(palette.accent)

                Text(currentModel)
                    .font(RoxyFont.labelSmall)
                    .foregroundStyle(palette.text)
                    .lineLimit(1)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10))
                    .foregroundStyle(palette.textSubtle)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(palette.elevated, in: Capsule())
            .overlay(Capsule().strokeBorder(palette.edgeStrong, lineWidth: 1))
        }
        .buttonStyle(.pressScale)
        .accessibilityLabel("Change model")
    }

    private var sendButton: some View {
        Button(action: onSubmit) {
            Image(systemName: "arrow.up")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isSendActive ? .black : palette.textSubtle)
                .frame(width: 34, height: 34)
                .background(
                    // Literal white, not the polarity token — the Kotlin pins it
                    // too, so the button matches on both clients.
                    isSendActive ? Color.white : palette.white.opacity(0.25),
                    in: RoxyRadius.shape(10)
                )
        }
        .buttonStyle(.pressScale)
        .disabled(!isSendActive)
        .accessibilityLabel("Send")
    }
}

#Preview {
    @Previewable @State var text = ""
    return RoxyTheme {
        VStack {
            Spacer()
            ChatComposer(text: text, onTextChange: { text = $0 }, onSubmit: {})
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
        }
    }
}
