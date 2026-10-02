//
//  MimoDatePickerTextField.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 25.09.23.
//

import SwiftUI

/// Date-of-birth field: shows the chosen date and opens `MimoDateOfBirthSheet`
/// to change it.
struct MimoDatePickerTextField: View {

    var title: String
    var placeholder: String
    @Binding var date: Date?

    var body: some View {
        Button {
            VibrateManager.vibrate()
            MimoDateOfBirthPicker.present(selected: date) { date = $0 }
        } label: {
            ZStack {
                Color.appBackground
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(title)
                            .font(.robotoLight13)
                            .foregroundColor(.appLabel)
                        Text(date.map(MimoDateOfBirthPicker.displayString(from:)) ?? placeholder)
                            .font(.robotoRegular16)
                            .foregroundColor(date == nil ? .gray5 : .appLabel)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "calendar")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.gray5)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 15)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.appLabel, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .frame(height: 63)
        .frame(maxWidth: .infinity)
    }
}
