//
//  EVOnboardingView.swift
//  MimoBike
//
//  Created by Yurka Babayan on 07.03.25.
//

import SwiftUI
import Kingfisher

struct EVOnboardingView: View {
    
    @ObservedObject var viewModel: EVOnboardingViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $viewModel.currentPage) {
                ForEach(viewModel.items) { item in
                    VStack(spacing: 32) {
                        
                        KFImage(item.image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.top, 12)
                            .padding(.horizontal, 20)
                            .tag(item.id)
                        
                        VStack(alignment: .center, spacing: 12) {
                            Text(item.title)
                                .font(.robotoBold24)
                                .foregroundColor(Color.evText9)
                                .multilineTextAlignment(.center)
                            
                            Text(item.subTitle)
                                .font(.robotoRegular17)
                                .foregroundColor(Color.evText8)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            Button {
                withAnimation {
                    if viewModel.currentPage < viewModel.items.count - 1 {
                        viewModel.currentPage += 1
                    }
                }
            } label: {
                Text("MOBILE_global_next".localized())
                    .font(.robotoBold15)
                    .foregroundColor(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.evbrandCyan80)
                    .clipShape(RoundedRectangle(cornerRadius: 50))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }
            .disabled(viewModel.currentPage == viewModel.items.count - 1)
            
            HStack {
                ForEach(0..<viewModel.items.count, id: \.self) { index in
                    Circle()
                        .fill(index == viewModel.currentPage ? Color.evBrandGreen : Color.evStroke)
                        .frame(width: 6, height: 6)
                }
            }
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.evMainBg1)
        .ignoresSafeArea(edges: .top)
        .compactNavigationView(
            title: "EV_CHARGER_how_to_use".localized(),
            backAction: { viewModel.back() }
        )
        .onAppear {
            UIPageControl.appearance().currentPageIndicatorTintColor = UIColor.black
            UIPageControl.appearance().pageIndicatorTintColor = UIColor.gray
        }
    }
}
