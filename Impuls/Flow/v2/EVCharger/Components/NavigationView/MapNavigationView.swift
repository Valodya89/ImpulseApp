//
//  MapNavigationView.swift
//  MimoBike
//
//  Created by Yurka Babayan on 05.02.25.
//

import SwiftUI

struct MapNavigationViewModifier: ViewModifier {
    
    var value: Decimal
    var subTitle: String
    var backAction: Action
    var plusAction: Action
    var bellAction: Action
    
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            MapNavigationView(
                value: value,
                subTitle: subTitle,
                backAction: backAction,
                plusAction: plusAction,
                bellAction: bellAction
            )
            content
        }
        .ignoresSafeArea(edges: .top)
    }
}

extension MapNavigationViewModifier {
    func MapNavigationView(
        value: Decimal,
        subTitle: String,
        backAction: @escaping Action,
        plusAction: @escaping Action,
        bellAction: @escaping Action
    ) -> some View {
        HStack(spacing: 0) {
            Image(.leftChevronIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 22, height: 22)
                .padding(10)
                .contentShape(Rectangle())
                .onTapGesture { backAction() }
            
            Spacer()
            
//            VStack(spacing: 5) {
//                HStack(spacing: 6) {
//                    Text("\(String(describing: value)) AMD")
//                        .font(.system(size: 18))
//                        .foregroundColor(.mimoDarkGray)
//                    
//                    Image(.icPlus)
//                        .renderingMode(.template)
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//                        .frame(width: 16, height: 16)
//                        .foregroundColor(Color.white)
//                        .background(
//                            Circle()
//                                .fill(Color.evbrandCyan80)
//                                .frame(width: 22, height: 22)
//                        )
//                        .onTapGesture { plusAction() }
//                }
//                
//                Text(subTitle)
//                    .font(.system(size: 13))
//                    .foregroundColor(Color.gray4)
//            }
            
            Spacer()
            
            Image(.bellIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 28)
                .padding(10)
                .contentShape(Rectangle())
                .onTapGesture { bellAction() }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 38)
        .padding(.vertical, 12)
        .padding(.horizontal)
        .background(BlurView(style: .light).blur(radius: 2))
        .clipped()
    }
}

extension View {
    func mapNavigationView(
        value: Decimal,
        subTitle: String,
        backAction: @escaping Action,
        plusAction: @escaping Action,
        bellAction: @escaping Action
    ) -> some View {
        modifier(
            MapNavigationViewModifier(
                value: value,
                subTitle: subTitle,
                backAction: backAction,
                plusAction: plusAction,
                bellAction: bellAction
            )
        )
    }
}
