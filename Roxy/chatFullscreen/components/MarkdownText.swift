//
//  MarkdownText.swift
//  Roxy
//

import Foundation
import SwiftUI

// MARK: - Block parsing

enum MarkdownBlock: Equatable, Identifiable {
    case paragraph(String)
    case heading(level: Int, text: String)
    case codeBlock(language: String, code: String)
    case bulletItem(String)
    case numberedItem(number: String, text: String)
    case blockquote(String)

    var id: String { UUID().uuidString }
}

private let numberedListRegex = /^(\d+)\.\s+(.*)$/
private let bulletListRegex = /^[-*]\s+(.*)$/

/// Covers what an agent emits — paragraphs, headings, fenced code, flat lists,
/// quotes. No nested lists, tables or reference links.
func parseMarkdownBlocks(_ markdown: String) -> [MarkdownBlock] {
    guard !markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }

    var blocks: [MarkdownBlock] = []
    let lines = markdown.components(separatedBy: .newlines)
    var i = 0

    while i < lines.count {
        let line = lines[i]
        let leadingTrimmed = String(line.drop(while: { $0 == " " || $0 == "\t" }))

        // 1. Fenced code block
        if leadingTrimmed.hasPrefix("```") {
            let language = leadingTrimmed
                .dropFirst(3)
                .trimmingCharacters(in: .whitespaces)
            var codeLines: [String] = []
            i += 1
            while i < lines.count,
                  !lines[i].drop(while: { $0 == " " || $0 == "\t" }).hasPrefix("```") {
                codeLines.append(lines[i])
                i += 1
            }
            if i < lines.count { i += 1 } // skip the closing fence
            blocks.append(.codeBlock(language: language, code: codeLines.joined(separator: "\n")))
            continue
        }

        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // 2. Blank line
        if trimmed.isEmpty {
            i += 1
            continue
        }

        // 3. Heading
        if trimmed.hasPrefix("#") {
            let level = trimmed.prefix(while: { $0 == "#" }).count
            if (1...6).contains(level),
               trimmed.count > level,
               Array(trimmed)[level] == " " {
                let text = String(trimmed.dropFirst(level + 1)).trimmingCharacters(in: .whitespaces)
                blocks.append(.heading(level: level, text: text))
                i += 1
                continue
            }
        }

        // 4. Blockquote
        if trimmed.hasPrefix(">") {
            var quoteLines = [String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)]
            i += 1
            while i < lines.count, lines[i].trimmingCharacters(in: .whitespaces).hasPrefix(">") {
                let quoted = lines[i].trimmingCharacters(in: .whitespaces)
                quoteLines.append(String(quoted.dropFirst()).trimmingCharacters(in: .whitespaces))
                i += 1
            }
            blocks.append(.blockquote(quoteLines.joined(separator: "\n")))
            continue
        }

        // 5. Numbered list: "1. ", "12. "
        if let match = trimmed.wholeMatch(of: numberedListRegex) {
            blocks.append(.numberedItem(number: String(match.1), text: String(match.2)))
            i += 1
            continue
        }

        // 6. Bullet list: "- ", "* "
        if let match = trimmed.wholeMatch(of: bulletListRegex) {
            blocks.append(.bulletItem(String(match.1)))
            i += 1
            continue
        }

        // 7. Paragraph: take lines until the next delimiter or a blank line
        var paragraphLines: [String] = []
        while i < lines.count {
            let current = lines[i]
            let currentTrimmed = current.trimmingCharacters(in: .whitespaces)
            if currentTrimmed.isEmpty
                || currentTrimmed.hasPrefix("```")
                || currentTrimmed.hasPrefix("#")
                || currentTrimmed.hasPrefix(">")
                || currentTrimmed.wholeMatch(of: numberedListRegex) != nil
                || currentTrimmed.wholeMatch(of: bulletListRegex) != nil {
                break
            }
            paragraphLines.append(current)
            i += 1
        }
        if !paragraphLines.isEmpty {
            blocks.append(.paragraph(paragraphLines.joined(separator: "\n")))
        }
    }

    return blocks
}

// MARK: - Inline formatting

/// Alternation order is load-bearing: `***x***` before `**x**` before `*x*`, or
/// the shorter pattern eats the longer one's opening delimiter. Group numbers
/// match the Kotlin's: 2 code, 4 both, 6/8 bold, 10/12 italic, 14/15 link.
private let inlineMarkdownPattern = """
(`([^`]+)`)\
|(\\*\\*\\*([^*]+)\\*\\*\\*)\
|(\\*\\*([^*]+)\\*\\*)\
|(__(?!_)([^_]+)__)\
|(\\*([^*]+)\\*)\
|(_([^_]+)_)\
|(\\[([^\\]]+)\\]\\(([^)]+)\\))
"""

private let inlineMarkdownRegex = try? NSRegularExpression(pattern: inlineMarkdownPattern)

func buildMarkdownAttributedString(
    _ text: String,
    palette: RoxyPalette
) -> AttributedString {
    guard let regex = inlineMarkdownRegex else { return AttributedString(text) }

    var result = AttributedString()
    let ns = text as NSString
    var cursor = 0

    for match in regex.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
        let start = match.range.location
        let end = start + match.range.length

        if start > cursor {
            result += AttributedString(ns.substring(with: NSRange(location: cursor, length: start - cursor)))
        }

        func group(_ index: Int) -> String? {
            let range = match.range(at: index)
            return range.location == NSNotFound ? nil : ns.substring(with: range)
        }

        if let code = group(2) {
            // The spaces ARE the padding: an attribute run cannot carry inset.
            // Same workaround as the Kotlin, and the same caveat when it wraps.
            var run = AttributedString(" \(code) ")
            run.font = RoxyFont.bodyLargeMono
            run.backgroundColor = palette.surface2
            run.foregroundColor = palette.accent
            result += run
        } else if let boldItalic = group(4) {
            var run = AttributedString(boldItalic)
            run.font = RoxyFont.bodyLarge.bold().italic()
            run.foregroundColor = palette.text
            result += run
        } else if let bold = group(6) ?? group(8) {
            var run = AttributedString(bold)
            run.font = RoxyFont.bodyLarge.bold()
            run.foregroundColor = palette.text
            result += run
        } else if let italic = group(10) ?? group(12) {
            var run = AttributedString(italic)
            run.font = RoxyFont.bodyLarge.italic()
            run.foregroundColor = palette.text
            result += run
        } else if let linkText = group(14) {
            var run = AttributedString(linkText)
            run.foregroundColor = palette.accent
            run.underlineStyle = .single
            result += run
        }

        cursor = end
    }

    if cursor < ns.length {
        result += AttributedString(ns.substring(from: cursor))
    }

    return result
}

// MARK: - Rendering

struct MarkdownText: View {
    @Environment(\.roxyPalette) private var palette

    let markdown: String

    private var blocks: [MarkdownBlock] {
        parseMarkdownBlocks(markdown)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                view(for: block)
            }
        }
    }

    @ViewBuilder
    private func view(for block: MarkdownBlock) -> some View {
        switch block {
        case .paragraph(let text):
            Text(buildMarkdownAttributedString(text, palette: palette))
                .font(RoxyFont.bodyLarge)
                .roxyLineHeight(.bodyLarge)
                .foregroundStyle(palette.text)
                .frame(maxWidth: .infinity, alignment: .leading)

        case .heading(let level, let text):
            Text(buildMarkdownAttributedString(text, palette: palette))
                .font(headingFont(level))
                .roxyLineHeight(headingStyle(level))
                .foregroundStyle(palette.text)
                .frame(maxWidth: .infinity, alignment: .leading)

        case .codeBlock(let language, let code):
            CodeBlockCard(language: language, code: code)

        case .bulletItem(let text):
            HStack(alignment: .top, spacing: 0) {
                Text("•")
                    .font(RoxyFont.bodyLarge)
                    .foregroundStyle(palette.accent)
                    .padding(.leading, 2)
                    .padding(.trailing, 8)

                Text(buildMarkdownAttributedString(text, palette: palette))
                    .font(RoxyFont.bodyLarge)
                    .roxyLineHeight(.bodyLarge)
                    .foregroundStyle(palette.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

        case .numberedItem(let number, let text):
            HStack(alignment: .top, spacing: 0) {
                Text("\(number).")
                    .font(RoxyFont.bodyLargeMono)
                    .fontWeight(.semibold)
                    .foregroundStyle(palette.textMuted)
                    .padding(.leading, 2)
                    .padding(.trailing, 8)

                Text(buildMarkdownAttributedString(text, palette: palette))
                    .font(RoxyFont.bodyLarge)
                    .roxyLineHeight(.bodyLarge)
                    .foregroundStyle(palette.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

        case .blockquote(let text):
            HStack(alignment: .top, spacing: 10) {
                RoxyRadius.shape(RoxyRadius.extraSmall)
                    .fill(palette.accent)
                    .frame(width: 3, height: 22)

                Text(buildMarkdownAttributedString(text, palette: palette))
                    .font(RoxyFont.bodyMedium)
                    .roxyLineHeight(.bodyMedium)
                    .italic()
                    .foregroundStyle(palette.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 4)
        }
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: RoxyFont.titleLarge.bold()
        case 2: RoxyFont.titleMedium.bold()
        default: RoxyFont.titleSmall.weight(.semibold)
        }
    }

    private func headingStyle(_ level: Int) -> RoxyTextStyle {
        switch level {
        case 1: .titleLarge
        case 2: .titleMedium
        default: .titleSmall
        }
    }
}

/// Code scrolls sideways rather than wrapping — a wrapped line of code is a
/// line you have to re-read to trust.
struct CodeBlockCard: View {
    @Environment(\.roxyPalette) private var palette

    let language: String
    let code: String

    var body: some View {
        VStack(spacing: 0) {
            if !language.trimmingCharacters(in: .whitespaces).isEmpty {
                HStack {
                    Text(language)
                        .font(RoxyFont.labelSmallMono)
                        .foregroundStyle(palette.textMuted)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(palette.elevated)

                RoxyDivider(color: palette.edge)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(RoxyFont.bodySmallMono)
                    .foregroundStyle(palette.text)
                    .textSelection(.enabled)
                    .padding(12)
            }
        }
        .roxySurface(palette.surface2, radius: RoxyRadius.medium)
        .clipShape(RoxyRadius.shape(RoxyRadius.medium))
    }
}

struct ReasoningCard: View {
    @Environment(\.roxyPalette) private var palette

    let reasoning: ReasoningUiModel

    /// Local, unlike every other expansion here: wanting to see the thinking is
    /// a passing choice, not session state. Seeded once, so a later change to
    /// `reasoning.isExpanded` is ignored — the same trade `rememberSaveable`
    /// makes.
    @State private var isExpanded: Bool

    init(reasoning: ReasoningUiModel) {
        self.reasoning = reasoning
        _isExpanded = State(initialValue: reasoning.isExpanded)
    }

    var body: some View {
        Button {
            isExpanded.toggle()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                header

                if isExpanded {
                    Spacer().frame(height: 8)
                    RoxyDivider(color: palette.edge)
                    Spacer().frame(height: 8)

                    Text(reasoning.text)
                        .font(RoxyFont.bodySmall)
                        .roxyLineHeight(.bodySmall)
                        .italic()
                        .foregroundStyle(palette.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressScale)
        .roxySurface(palette.surface2, radius: RoxyRadius.medium)
        .clipShape(RoxyRadius.shape(RoxyRadius.medium))
        .animation(RoxyMotion.outQuart(0.16), value: isExpanded)
    }

    private var header: some View {
        HStack(spacing: 0) {
            Image(systemName: "sparkles")
                .font(.system(size: 13))
                .foregroundStyle(palette.accent)
                .frame(width: 15, height: 15)

            Spacer().frame(width: 8)

            Text("Thinking Process")
                .font(RoxyFont.labelMedium)
                .fontWeight(.semibold)
                .foregroundStyle(palette.textMuted)

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(palette.textSubtle)
                .frame(width: 16, height: 16)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
                .accessibilityLabel(isExpanded ? "Collapse" : "Expand")
        }
    }
}

#Preview {
    RoxyTheme {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                MarkdownText(markdown: """
                # Heading one
                A paragraph with **bold**, *italic*, `inline code` and a [link](https://example.com).

                - First bullet
                - Second bullet

                1. First step
                2. Second step

                > A quoted aside.

                ```swift
                let palette = RoxyPalette.dark
                ```
                """)

                ReasoningCard(
                    reasoning: ReasoningUiModel(
                        id: "r1",
                        text: "Checking the theme tokens before editing the view.",
                        isExpanded: true
                    )
                )
            }
            .padding(20)
        }
    }
}
