//
//  ModelSelectorSheet.swift
//  Roxy
//

import SwiftUI

/// NOTE: every color here is a literal hex, matching the Kotlin, which also
/// hardcodes them. This surface does NOT follow the theme — it stays dark under
/// the light theme on both clients. Ported as-is so the two do not diverge; when
/// the Kotlin moves to tokens, this should follow in the same commit.
struct ModelSelectorSheet: View {
    let selectedModel: String
    let onModelSelected: (String) -> Void

    @State private var searchQuery = ""

    private enum Ink {
        static let container = Color(hex: 0x131418)
        static let content = Color(hex: 0xEEEEEE)
        static let grabber = Color(hex: 0x2E2F38)
        static let searchFill = Color(hex: 0x1C1D23)
        static let searchBorder = Color(hex: 0x2B2C36)
        static let searchIcon = Color(hex: 0x7A7C88)
        static let searchText = Color(hex: 0xE4E4E7)
        static let searchPlaceholder = Color(hex: 0x6B6D7A)
        static let clearIcon = Color(hex: 0x8E90A0)
        static let sectionLabel = Color(hex: 0x888B98)
        static let selectedRow = Color(hex: 0x1B2433)
        static let rowText = Color(hex: 0xD4D4D8)
        static let cyan = Color(hex: 0x38BDF8)
        static let green = Color(hex: 0x4ADE80)
        static let claudeOrange = Color(hex: 0xE06C43)
        static let sectionOrange = Color(hex: 0xD97706)
    }

    private var filteredModels: [RoxyModelItem] {
        let query = searchQuery.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return desktopRoxyModels }
        return desktopRoxyModels.filter { $0.id.localizedCaseInsensitiveContains(query) }
    }

    /// In the list's own order: the sections are a ranking, so sorting them
    /// would destroy the only information the grouping carries.
    private var sections: [(name: String, models: [RoxyModelItem])] {
        var order: [String] = []
        var grouped: [String: [RoxyModelItem]] = [:]
        for model in filteredModels {
            if grouped[model.section] == nil { order.append(model.section) }
            grouped[model.section, default: []].append(model)
        }
        return order.map { ($0, grouped[$0] ?? []) }
    }

    var body: some View {
        VStack(spacing: 10) {
            Capsule()
                .fill(Ink.grabber)
                .frame(width: 36, height: 4)
                .padding(.vertical, 10)

            searchBar

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 1, pinnedViews: []) {
                    ForEach(sections, id: \.name) { section in
                        sectionHeader(section.name)

                        // Section + id, as in the Kotlin: the id alone is not
                        // unique across sections.
                        ForEach(section.models, id: \.rowKey) { model in
                            modelRow(model)
                        }
                    }
                }
            }
            .frame(maxHeight: 480)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Ink.container)
        .foregroundStyle(Ink.content)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Ink.container)
        .colorScheme(.dark)
    }

    private var searchBar: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(Ink.searchIcon)
                .accessibilityLabel("Search")

            TextField(
                "",
                text: $searchQuery,
                prompt: Text("Search models...").foregroundStyle(Ink.searchPlaceholder)
            )
            .textFieldStyle(.plain)
            .font(.system(size: 13.5))
            .foregroundStyle(Ink.searchText)
            .tint(Ink.cyan)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)

            if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Ink.clearIcon)
                }
                .buttonStyle(.pressScale)
                .accessibilityLabel("Clear")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Ink.searchFill, in: RoxyRadius.shape(9))
        .overlay(RoxyRadius.shape(9).strokeBorder(Ink.searchBorder, lineWidth: 1))
    }

    private func sectionHeader(_ name: String) -> some View {
        HStack(spacing: 6) {
            switch name {
            case "PINNED":
                Image(systemName: "pin.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Ink.sectionLabel)
            case "LATEST - CLAUDE (SUBSCRIPTION)":
                Image(systemName: "clock")
                    .font(.system(size: 10))
                    .foregroundStyle(Ink.sectionLabel)
            default:
                ClaudeAsteriskIcon(color: Ink.sectionOrange)
                    .frame(width: 12, height: 12)
            }

            Text(name)
                .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                .tracking(1)
                .foregroundStyle(Ink.sectionLabel)
        }
        .padding(.top, 8)
        .padding(.bottom, 2)
        .padding(.leading, 6)
    }

    private func modelRow(_ model: RoxyModelItem) -> some View {
        let isSelected = model.id == selectedModel

        return Button {
            onModelSelected(model.id)
        } label: {
            HStack(spacing: 0) {
                ZStack {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Ink.cyan)
                            .accessibilityLabel("Selected")
                    }
                }
                .frame(width: 16, height: 16)

                Spacer().frame(width: 6)

                Group {
                    if model.provider == .google {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                            .foregroundStyle(Ink.cyan)
                            .accessibilityLabel("Gemini")
                    } else {
                        ClaudeAsteriskIcon(color: Ink.claudeOrange)
                            .frame(width: 14, height: 14)
                    }
                }
                .frame(width: 14, height: 14)

                Spacer().frame(width: 8)

                Text(model.id)
                    .font(.system(size: 12.5, design: .monospaced))
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? Color.white : Ink.rowText)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 6) {
                    if model.hasReasoning {
                        Image(systemName: "brain")
                            .font(.system(size: 12))
                            .foregroundStyle(Ink.cyan)
                            .accessibilityLabel("Reasoning")
                    }
                    if model.hasTools {
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.system(size: 11))
                            .foregroundStyle(Ink.green)
                            .accessibilityLabel("Tools")
                    }
                    if model.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Ink.cyan)
                            .accessibilityLabel("Pinned")
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5.5)
            .contentShape(Rectangle())
            .background(
                isSelected ? Ink.selectedRow : .clear,
                in: RoxyRadius.shape(6)
            )
        }
        .buttonStyle(.pressScale)
    }
}

struct ClaudeAsteriskIcon: View {
    var color: Color = Color(hex: 0xE06C43)

    var body: some View {
        Canvas { context, size in
            let radius = min(size.width, size.height) / 2
            let center = CGPoint(x: size.width / 2, y: size.height / 2)

            for i in 0..<8 {
                let angle = Double(i) * 45 * .pi / 180
                var path = Path()
                path.move(to: CGPoint(
                    x: center.x + radius * 0.28 * cos(angle),
                    y: center.y + radius * 0.28 * sin(angle)
                ))
                path.addLine(to: CGPoint(
                    x: center.x + radius * cos(angle),
                    y: center.y + radius * sin(angle)
                ))
                context.stroke(
                    path,
                    with: .color(color),
                    style: StrokeStyle(lineWidth: 1.9, lineCap: .round)
                )
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    ModelSelectorSheet(selectedModel: "gemini-3.8-flash-high", onModelSelected: { _ in })
}
