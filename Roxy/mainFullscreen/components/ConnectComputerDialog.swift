//
//  ConnectComputerDialog.swift
//  Roxy
//

import SwiftUI

/// A scrim plus a centred card, not a sheet: the Kotlin uses a `Dialog`, and a
/// sheet would put the fields under the keyboard on shorter phones.
struct ConnectComputerDialog: View {
    @Environment(\.roxyPalette) private var palette

    let isConnecting: Bool
    let errorMessage: String?
    let onDismiss: () -> Void
    let onConnect: (String, String) -> Void
    var onScanQrCode: () -> Void = {}
    var qrFeedbackMessage: String?
    var initialTokenOrUrl: String = ""
    var initialPin: String = ""

    @State private var tokenInput: String
    @State private var pinInput: String
    @FocusState private var focusedField: Field?

    private enum Field { case token, pin }

    init(
        isConnecting: Bool,
        errorMessage: String?,
        onDismiss: @escaping () -> Void,
        onConnect: @escaping (String, String) -> Void,
        onScanQrCode: @escaping () -> Void = {},
        qrFeedbackMessage: String? = nil,
        initialTokenOrUrl: String = "",
        initialPin: String = ""
    ) {
        self.isConnecting = isConnecting
        self.errorMessage = errorMessage
        self.onDismiss = onDismiss
        self.onConnect = onConnect
        self.onScanQrCode = onScanQrCode
        self.qrFeedbackMessage = qrFeedbackMessage
        self.initialTokenOrUrl = initialTokenOrUrl
        self.initialPin = initialPin
        _tokenInput = State(initialValue: initialTokenOrUrl)
        _pinInput = State(initialValue: initialPin)
    }

    private var canConnect: Bool {
        !tokenInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && pinInput.trimmingCharacters(in: .whitespaces).count == 6
            && !isConnecting
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            ScrollView {
                card
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .transition(.opacity)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            qrButton

            if let qrFeedbackMessage {
                qrFeedbackBanner(qrFeedbackMessage)
            }

            manualDivider

            field(
                label: "LINK OR TOKEN",
                icon: "link",
                placeholder: "Paste https://roxy.gg/remote#... or token",
                text: $tokenInput,
                field: .token
            )

            field(
                label: "6-DIGIT PIN",
                icon: "key",
                placeholder: "e.g. 123456",
                text: $pinInput,
                field: .pin,
                isNumeric: true
            )

            if let errorMessage {
                errorAlert(errorMessage)
            }

            Spacer().frame(height: 2)

            actions
        }
        .padding(22)
        .background(palette.elevated, in: RoxyRadius.shape(20))
        .roxyEdge(radius: 20, style: .strong, bevelSpan: RoxyBevelSpan.panel)
        .roxyFloatShadow(palette)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "desktopcomputer")
                .font(.system(size: 22))
                .foregroundStyle(palette.text)
                .frame(width: 42, height: 42)
                .roxySurface(palette.surface2, radius: RoxyRadius.medium)

            VStack(alignment: .leading, spacing: 0) {
                Text("Connect PC")
                    .font(RoxyFont.titleMedium)
                    .fontWeight(.bold)
                    .foregroundStyle(palette.text)

                Text("Roxy Remote Workspace")
                    .font(RoxyFont.bodySmall)
                    .foregroundStyle(palette.textMuted)
            }
        }
    }

    private var qrButton: some View {
        Button(action: onScanQrCode) {
            HStack(spacing: 10) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 20))
                    .foregroundStyle(palette.accent)

                Text("Scan QR Code from PC")
                    .font(RoxyFont.titleSmall)
                    .fontWeight(.semibold)
                    .foregroundStyle(palette.text)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .roxySurface(palette.surface2, radius: RoxyRadius.medium, edge: .strong)
        }
        .buttonStyle(.pressScale)
        .disabled(isConnecting)
        .accessibilityLabel("Scan QR Code")
    }

    private func qrFeedbackBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(palette.success)

            Text(message)
                .font(RoxyFont.bodySmall)
                .foregroundStyle(palette.text)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(palette.surface2, in: RoxyRadius.shape(10))
        .overlay(RoxyRadius.shape(10).strokeBorder(palette.success, lineWidth: 1))
    }

    private var manualDivider: some View {
        HStack(spacing: 10) {
            RoxyDivider()

            Text("OR ENTER MANUALLY")
                .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                .tracking(1.1)
                .foregroundStyle(palette.textSubtle)
                .fixedSize()

            RoxyDivider()
        }
    }

    private func field(
        label: String,
        icon: String,
        placeholder: String,
        text: Binding<String>,
        field: Field,
        isNumeric: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(RoxyFont.labelSmallMono)
                .fontWeight(.semibold)
                .tracking(1.1)
                .foregroundStyle(palette.textSubtle)

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(palette.textMuted)

                TextField(
                    "",
                    text: text,
                    prompt: Text(placeholder)
                        .font(RoxyFont.bodySmall)
                        .foregroundStyle(palette.textSubtle)
                )
                .textFieldStyle(.plain)
                .font(RoxyFont.bodyMedium)
                .foregroundStyle(palette.text)
                .tint(palette.accent)
                .focused($focusedField, equals: field)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(isNumeric ? .numberPad : .URL)
                .submitLabel(isNumeric ? .done : .next)
                .onSubmit {
                    if isNumeric {
                        if canConnect { onConnect(tokenInput, pinInput) }
                    } else {
                        focusedField = .pin
                    }
                }
                .onChange(of: text.wrappedValue) { _, newValue in
                    // Refuse extra characters here rather than failing at
                    // Connect.
                    if isNumeric, newValue.count > 6 {
                        text.wrappedValue = String(newValue.prefix(6))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .roxySurface(
                palette.surface2,
                radius: RoxyRadius.medium,
                edge: focusedField == field ? .strong : .normal
            )
            .animation(RoxyMotion.outQuart(0.14), value: focusedField)
        }
    }

    /// `accent`, not `danger`, matching the Kotlin — see the note in
    /// `SettingsView`. A failed pairing reads as a highlight, not a problem.
    private func errorAlert(_ message: String) -> some View {
        Text(message)
            .font(RoxyFont.bodySmall)
            .roxyLineHeight(.bodySmall)
            .foregroundStyle(palette.accent)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(palette.surface, in: RoxyRadius.shape(RoxyRadius.small))
            .overlay(
                RoxyRadius.shape(RoxyRadius.small)
                    .strokeBorder(palette.accent, lineWidth: 1)
            )
    }

    private var actions: some View {
        HStack(spacing: 10) {
            Button(action: onDismiss) {
                Text("Cancel")
                    .font(RoxyFont.labelLarge)
                    .foregroundStyle(palette.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .overlay(
                        RoxyRadius.shape(RoxyRadius.medium)
                            .strokeBorder(palette.edge, lineWidth: 1)
                    )
            }
            .buttonStyle(.pressScale)

            Button {
                focusedField = nil
                onConnect(tokenInput, pinInput)
            } label: {
                HStack(spacing: 8) {
                    if isConnecting {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .controlSize(.small)
                            .tint(palette.bg)

                        Text("Connecting...")
                    } else {
                        Text("Connect")
                    }
                }
                .font(RoxyFont.labelLarge)
                .foregroundStyle(canConnect ? palette.bg : palette.textSubtle)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    canConnect ? palette.accent : palette.surface2,
                    in: RoxyRadius.shape(RoxyRadius.medium)
                )
            }
            .buttonStyle(.pressScale)
            .disabled(!canConnect)
        }
    }
}

#Preview {
    RoxyTheme {
        ConnectComputerDialog(
            isConnecting: false,
            errorMessage: "Could not reach the relay. Check the PIN and try again.",
            onDismiss: {},
            onConnect: { _, _ in },
            qrFeedbackMessage: "Scanned Desktop PC"
        )
    }
}
