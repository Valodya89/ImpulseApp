//
//  CompactNavigationView.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 26.02.25.
//

import SwiftUI


struct CompactNavigationViewModifier: ViewModifier {
    
    var title: String
    var backAction: Action?
    var rightAction: Action?
    var style: CompactNavigationViewModifier.NavigationStyle
    
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            compactNavigationView(
                title: title,
                backAction: backAction,
                rightAction: rightAction,
                style: style
            )
            content
        }
    }
}

extension CompactNavigationViewModifier {
    func compactNavigationView(
        title: String,
        backAction: Action?,
        rightAction: Action?,
        style: CompactNavigationViewModifier.NavigationStyle
    ) -> some View {
        
        HStack(alignment: .top, spacing: 0) {
            Spacer()
            
            
            Text(title)
                .font(.robotoBold15)
                .foregroundColor(.black60)

            
            Spacer()
            
        }
        .overlay(rightView, alignment: .trailing)
        .overlay(leftView, alignment: .leading)
        .padding(.vertical, 15)
        .padding(.horizontal, 20)
        .clipped()
    }
    @ViewBuilder
    var rightView: some View {
        if let rightAction {
            Button {
                rightAction()
            } label: {
                Text("EV_CHARGER_reset".localized())
                    .font(.robotoRegular15)
                    .foregroundColor(.black60)
                    .contentShape(Rectangle())
            }

        }
    }
    
    @ViewBuilder
    var leftView: some View {
        if let backAction {
            Button {
                backAction()
            } label: {
                switch style {
                case .Sheet:
                    Image(.cancelMark)
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.black60)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                    
                case .Stack:
                    Image(.arrowLeft)
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.black60)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
            }

        }
    }
}

extension CompactNavigationViewModifier {
    enum NavigationStyle {
        case Sheet
        case Stack
    }
}

extension View {
    func compactNavigationView(
        title: String,
        backAction: Action? = nil,
        rightAction: Action? = nil,
        style: CompactNavigationViewModifier.NavigationStyle = .Stack
    ) -> some View {
        modifier(
            CompactNavigationViewModifier(
                title: title,
                backAction: backAction,
                rightAction: rightAction,
                style: style
            )
        )
    }
}
