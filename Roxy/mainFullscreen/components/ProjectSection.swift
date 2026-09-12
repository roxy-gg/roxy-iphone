//
//  ProjectSection.swift
//  Roxy
//

import SwiftUI

/// The project is a label, not a card; its sessions share one `surface` card
/// divided by hairlines. Cards inside cards lose the hierarchy they were for.
struct ProjectSection: View {
    @Environment(\.roxyPalette) private var palette

    let project: ProjectUiModel
    let onSessionSelected: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            VStack(spacing: 0) {
                ForEach(Array(project.sessions.enumerated()), id: \.element.id) { index, session in
                    SessionRow(session: session) {
                        onSessionSelected(session.id)
                    }

                    if index != project.sessions.count - 1 {
                        // Starts under the text column, clear of the status dots.
                        RoxyDivider()
                            .padding(.leading, 19)
                    }
                }
            }
            .roxySurface(palette.surface, radius: RoxyRadius.large, bevelSpan: RoxyBevelSpan.panel)
            .clipShape(RoxyRadius.shape(RoxyRadius.large))
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "folder")
                .font(.system(size: 13))
                .foregroundStyle(palette.textSubtle)
                .frame(width: 15, height: 15)

            Text(project.name)
                .font(RoxyFont.labelMedium)
                .foregroundStyle(palette.textMuted)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text("\(project.sessions.count)")
                .font(RoxyFont.labelSmall)
                .monospacedDigit()
                .foregroundStyle(palette.textSubtle)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 9)
    }
}

/// A session, as a tappable row inside its project's card.
struct SessionRow: View {
    @Environment(\.roxyPalette) private var palette

    let session: SessionUiModel
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 0) {
                // Marked twice: a larger accent dot AND a step up in surface.
                // Color alone fails anyone who cannot separate the two greens.
                ZStack {
                    Circle()
                        .fill(session.isActive ? palette.accent : palette.borderStrong)
                        .frame(
                            width: session.isActive ? 7 : 5,
                            height: session.isActive ? 7 : 5
                        )
                }
                .frame(width: 8, height: 8)

                Spacer().frame(width: 12)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(session.title)
                            .font(RoxyFont.titleMedium)
                            .foregroundStyle(palette.text)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(session.updatedAt)
                            .font(RoxyFont.labelSmall)
                            .monospacedDigit()
                            .foregroundStyle(palette.textSubtle)
                    }

                    Text(session.summary)
                        .font(RoxyFont.bodySmall)
                        .foregroundStyle(palette.textMuted)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer().frame(width: 7)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(palette.textSubtle)
                    .frame(width: 18, height: 18)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
            .background(session.isActive ? palette.surface2 : palette.surface)
        }
        .buttonStyle(.pressScale)
    }
}

#Preview {
    RoxyTheme {
        ProjectSection(
            project: ProjectUiModel(
                id: "project-1",
                name: "Project #1",
                sessions: [
                    SessionUiModel(id: "session-1", title: "Session #1", summary: "Building the Android client", updatedAt: "Now", isActive: true),
                    SessionUiModel(id: "session-2", title: "Session #2", summary: "Desktop theme parity", updatedAt: "18m"),
                    SessionUiModel(id: "session-3", title: "Session #3", summary: "Compose architecture", updatedAt: "Yesterday")
                ]
            ),
            onSessionSelected: { _ in }
        )
        .padding(20)
    }
}
