//
//  PickerSegmentedView.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 29.03.25.
//

import SwiftUI

struct PickerSegmentedView: View {

    @Binding var selectedOption: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            Text("EV_CHARGER_amount".localized())
                .foregroundColor(Color.evbrandCyan80)
                .font(.robotoBold16)
                .padding(.vertical, 8)
                .padding(.horizontal, 24)
                .background(selectedOption ? Color.clear : Color.evbrandCyan80.opacity(0.1))
                .clipShape(Capsule())
                .onTapGesture {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    withAnimation {
                        selectedOption = false
                    }
                }

            Text("EV_CHARGER_full_charge".localized())
                .foregroundColor(Color.evbrandCyan80)
                .font(.robotoBold16)
                .padding(.vertical, 8)
                .padding(.horizontal, 24)
                .background(selectedOption ? Color.evbrandCyan80.opacity(0.1) : Color.clear)
                .clipShape(Capsule())
                .onTapGesture {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    withAnimation {
                        selectedOption = true
                    }
                }
        }
        .padding(4)
        .background(Color.white)
        .clipShape(Capsule())
    }
}

#Preview {
    @State var selectedOption: Bool = false
    return PickerSegmentedView(selectedOption: $selectedOption)
}
