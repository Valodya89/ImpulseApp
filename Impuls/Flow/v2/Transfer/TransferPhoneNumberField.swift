//
//  TransferPhoneNumberField.swift
//  Impuls
//
//  Phone field of the transfer flow: flag + dial code + number, styled like
//  the login phone field (surface fill, separator hairline) with a brand
//  yellow focus ring while it is being edited.
//

import SwiftUI

struct TransferPhoneNumberField: View {

    let title: String
    let flag: String?
    let dialCode: String
    let placeholder: String
    @Binding var text: String
    /// Field is being edited: the border turns brand yellow.
    @Binding var isEditing: Bool
    let onPickCountry: () -> Void

    var body: some View {
        ZStack {
            Color.appBackground

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.robotoLight13)
                    .foregroundColor(.gray5)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 0) {
                    Button(action: {
                        VibrateManager.vibrate()
                        onPickCountry()
                    }) {
                        HStack(spacing: 8) {
                            Image(flag ?? "")
                                .resizable()
                                .frame(width: 18, height: 18)
                                .fixedSize()

                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.gray5)
                        }
                        // The glyphs are small; the row is 44pt tall so the
                        // tap target stays finger-sized.
                        .frame(height: 44)
                        .contentShape(Rectangle())
                    }

                    Text(dialCode)
                        .font(.robotoBold17)
                        .foregroundColor(.appLabel)
                        .padding(.leading, 10)

                    TextField(placeholder, text: $text, onEditingChanged: { editing in
                        isEditing = editing
                    })
                    .font(.robotoRegular17)
                    .foregroundColor(.appLabel)
                    .keyboardType(.phonePad)
                    .padding(.leading, 5)
                    .frame(height: 44)
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isEditing ? Color.brandYellow : Color.appSeparator, lineWidth: isEditing ? 1.5 : 1)
        )
        .animation(.easeOut(duration: 0.2), value: isEditing)
        .frame(height: 76)
        .frame(maxWidth: .infinity)
    }
}
