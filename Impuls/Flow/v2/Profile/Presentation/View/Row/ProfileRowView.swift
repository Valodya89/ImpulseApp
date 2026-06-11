//
//  ProfileRowView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 14.04.24.
//

import SwiftUI

struct ProfileRowView: View {
    
    let icon: String
    let title: String
    let type: ProfileRowView.RowType
    let isArrowVisible: Bool
    
    init(icon: String, title: String, type: ProfileRowView.RowType = .standard, isArrowVisible: Bool = true) {
        self.icon = icon
        self.title = title
        self.type = type
        self.isArrowVisible = isArrowVisible
    }
    
    var body: some View {
        ZStack {
            HStack(spacing: 12) {
                Image(icon)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(type.iconColor)
                
                Text(title)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(type.titleColor)
                
                Spacer()
                
                if isArrowVisible {
                    Image(systemName: "chevron.right")
                        .resizable()
                        .foregroundColor(.black025)
                        .frame(width: 8, height: 14)
                        .font(.title.weight(.light))
                        .padding(.trailing, 2)
                }
            }
            .padding(12)
        }
        .background(Color.white)
    }
}

extension ProfileRowView {
    enum RowType {
        case standard
        case destructive
        
        var titleColor: Color {
            switch self {
            case .standard:
                return .black075
            case .destructive:
                return .red500
            }
        }
        
        var iconColor: Color {
            switch self {
            case .standard:
                return .iconGray
            case .destructive:
                return .red500
            }
        }
    }
}
