//
//  StorySurveyView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 24.12.23.
//

import SwiftUI
import Kingfisher

struct StorySurveyView: View {
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    @EnvironmentObject private var viewModel: StoryViewModel
    
    var story: StoryPage
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                KFImage(story.background?.imageURL)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    Text(story.title)
                        .multilineTextAlignment(.center)
                        .font(.robotoSemibold40)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    
                    Text(story.content)
                        .multilineTextAlignment(.center)
                        .font(.robotoRegular20)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                        .lineLimit(3)
                        .minimumScaleFactor(0.5)
                    
                    if story.options.count > 3 {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(story.options, id: \.self) { option in
                                Button {
                                    viewModel.didSelect(option: option, pageNumber: story.number)
                                } label: {
                                    ZStack {
                                        if viewModel.isOptionSelected(option: option) {
                                            Color.mimoYellow500
                                        } else {
                                            Color.white
                                        }
                                        
                                        Text(option)
                                            .font(.robotoMedium16)
                                            .foregroundColor(Color.black075)
                                            .padding(.horizontal, 16)
                                    }
                                    .clipShape(Capsule())
                                }
                                .frame(height: 42)
                                .padding(.horizontal, 20)
                                .disabled(viewModel.isOptionSelected(option: option))
                            }
                        }
                        .padding(.bottom, 24)
                    } else {
                        VStack(spacing: 16) {
                            Text("")
                                .frame(height: 4)
                            
                            ForEach(story.options, id: \.self) { option in
                                Button {
                                    viewModel.didSelect(option: option, pageNumber: story.number)
                                } label: {
                                    ZStack {
                                        if viewModel.isOptionSelected(option: option) {
                                            Color.mimoYellow500
                                        } else {
                                            Color.white
                                        }
                                        
                                        Text(option)
                                            .font(.robotoMedium16)
                                            .foregroundColor(Color.black075)
                                            .padding(.horizontal, 16)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .clipShape(Capsule())
                                }
                                .frame(height: 42)
                                .padding(.horizontal, 20)
                                .disabled(viewModel.isOptionSelected(option: option))
                            }
                            
                            Text("")
                                .frame(height: 4)
                        }
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(32)
                        .padding(.bottom, 24)
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 74)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}
