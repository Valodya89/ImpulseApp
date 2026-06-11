//
//  StoryActionView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 24.12.23.
//

import SwiftUI
import Kingfisher

struct StoryActionView: View {
    
    @Environment(\.openURL) var openURL
    
    @EnvironmentObject private var viewModel: StoryViewModel

    var storyGroup: Story
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
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                    
                    Text(story.content)
                        .multilineTextAlignment(.center)
                        .font(.robotoRegular20)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                        .lineLimit(3)
                        .minimumScaleFactor(0.5)
                        
                    if let urlString = story.url, let url = URL(string: urlString) {
                        Button {
                            openURL(url)
                        } label: {
                            Text(story.urlButtonName ?? "")
                        }
                        .buttonStyle(MimoButton())
                        .padding(.bottom, 16)
                    }
                }
                .padding(.bottom, 74)
            }
        }
    }
}

struct ActivityViewController: UIViewControllerRepresentable {
        
    @Binding var shareURL: URL?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let containerViewController = UIViewController()
        
        return containerViewController

    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        guard let shareURL = shareURL, context.coordinator.presented == false else { return }
        
        context.coordinator.presented = true

        let activityViewController = UIActivityViewController(activityItems: [shareURL], applicationActivities: nil)
        activityViewController.completionWithItemsHandler = { activity, completed, returnedItems, activityError in
            self.shareURL = nil
            context.coordinator.presented = false

            if completed {
                // ...
            } else {
                // ...
            }
        }
        
        // Executing this asynchronously might not be necessary but some of my tests
        // failed because the view wasn't yet in the view hierarchy on the first pass of updateUIViewController
        //
        // There might be a better way to test for that condition in the guard statement and execute this
        // synchronously if we can be be sure updateUIViewController is invoked at least once after the view is added
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            uiViewController.present(activityViewController, animated: true)
        }
    }
    
    class Coordinator: NSObject {
        let parent: ActivityViewController
        
        var presented: Bool = false
        
        init(_ parent: ActivityViewController) {
            self.parent = parent
        }
    }
    
}
