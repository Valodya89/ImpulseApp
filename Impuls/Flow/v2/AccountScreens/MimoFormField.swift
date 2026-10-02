//
//  MimoFormField.swift
//  Impuls
//
//  Form rows for the redesigned account screens: a small label, the value
//  under it, and a red hairline sentence when the screen's existing validator
//  rejects the field. Rows stack inside a `.mimoCard()` separated by
//  `MimoFormDivider`, the same rhythm as `MimoListRow` but for input.
//

import SwiftUI

/// Hairline between two form rows, inset to the row's own content margin.
struct MimoFormDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.dividerColor)
            .frame(height: 1)
            .padding(.leading, 16)
    }
}

/// A typed row: label on top, editable text under it.
struct MimoFormTextRow: View {

    let title: String
    var placeholder: String = ""
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var autocapitalization: UITextAutocapitalizationType = .words
    var error: String?

    var body: some View {
        MimoFormRowContainer(title: title, error: error) {
            TextField(placeholder, text: $text)
                .font(.robotoRegular16)
                .foregroundColor(.appLabel)
                .keyboardType(keyboard)
                .autocapitalization(autocapitalization)
                .disableAutocorrection(true)
        }
    }
}

/// A row the rider cannot type into: tapping it opens the screen's existing
/// picker (date sheet, gender wheel) behind the SwiftUI skin.
struct MimoFormPickerRow: View {

    let title: String
    var placeholder: String = ""
    let value: String
    var glyph: String = "chevron.down"
    var error: String?
    let onTap: () -> Void

    var body: some View {
        MimoFormRowContainer(title: title, error: error) {
            HStack(spacing: 8) {
                Text(value.isEmpty ? placeholder : value)
                    .font(.robotoRegular16)
                    .foregroundColor(value.isEmpty ? .gray5 : .appLabel)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Image(systemName: glyph)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.gray5)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            VibrateManager.vibrate()
            onTap()
        }
    }
}

/// A row that only reports a value the rider cannot change here (the phone
/// number the account was created with).
struct MimoFormStaticRow: View {

    let title: String
    let value: String

    var body: some View {
        MimoFormRowContainer(title: title, error: nil) {
            Text(value)
                .font(.robotoRegular16)
                .foregroundColor(.gray5)
                .lineLimit(1)
        }
    }
}

/// Shared chrome of every form row.
struct MimoFormRowContainer<Content: View>: View {

    let title: String
    let error: String?
    let content: Content

    init(title: String, error: String?, @ViewBuilder content: () -> Content) {
        self.title = title
        self.error = error
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.robotoMedium12)
                .foregroundColor(.gray5)
                .lineLimit(1)

            content

            if let error, !error.isEmpty {
                Text(error)
                    .font(.robotoRegular12)
                    .foregroundColor(.errorRed)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(minHeight: 60)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
