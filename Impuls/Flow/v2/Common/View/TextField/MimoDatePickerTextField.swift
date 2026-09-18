//
//  MimoDatePickerTextField.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 25.09.23.
//

import SwiftUI

struct MimoDatePickerTextField: View {
    
    var title: String
    var placeholder: String
    @Binding var date: Date?
    
    var body: some View {
        ZStack {
            Color.appBackground
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(title)
                        .font(.robotoLight13)
                    
                    Spacer()
                }
                
                DatePickerInputView(date: $date,
                                    placeholder: placeholder)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 15)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.appLabel, lineWidth: 0.5)
        )
        .frame(height: 63)
        .frame(maxWidth: .infinity)
    }
}
