//
//  StoriesThumbView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 21.12.23.
//

import SwiftUI
import Kingfisher

struct StoriesThumbView: View {
    
    @EnvironmentObject var storyViewModel: StoryViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(storyViewModel.stories.value, id: \.id) { story in
                    KFImage(story.pages.first?.logo?.imageURL)
                        .resizable(resizingMode: .stretch)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black025, lineWidth: 1)
                        )
                        .onTapGesture {
                            storyViewModel.currentStory = story.id
                            storyViewModel.showStory = true
                        }
                }
            }
            .padding()
        }
        .fullScreenCover(isPresented: $storyViewModel.showStory, content: {
            StoryView().environmentObject(storyViewModel)
        })
    }
}
