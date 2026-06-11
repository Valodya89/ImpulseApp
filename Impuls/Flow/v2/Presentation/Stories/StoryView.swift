//
//  StoryView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 21.12.23.
//

import SwiftUI
import Combine
import Kingfisher
//import FirebaseAnalytics

struct StoryView: View {
    
    @EnvironmentObject var storyViewModel: StoryViewModel
    
    var body: some View {
        if storyViewModel.showStory {
            TabView(selection: $storyViewModel.currentStory) {
                ForEach(storyViewModel.stories.value) { story in
                    StoryCardView(story: story)
                        .environmentObject(storyViewModel)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.ignoresSafeArea(edges: .all))
        }
    }
}

struct StoryCardView: View {
    
    @EnvironmentObject var storyViewModel: StoryViewModel
    
    let story: Story
    
    @State var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @State var timerProgress: CGFloat = 0
    @State var isTimerRunning = true
    @GestureState var isPressing = false
    @State var shareURL: URL? = nil
    @State var currentIndex = 0
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                let index = min(Int(timerProgress), story.pages.count - 1)
                
                if story.pages[index].type == .link {
                    StoryActionView(storyGroup: story, story: story.pages[index])
                        .environmentObject(storyViewModel)
                } else {
                    StorySurveyView(story: story.pages[index])
                        .environmentObject(storyViewModel)
                }
                
                if shareURL != nil {
                    ActivityViewController(shareURL: $shareURL)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .cornerRadius(6)
            .overlay(
                HStack {
                    Rectangle()
                        .fill(.black.opacity(0.01))
                        .onTapGesture {
                            if (timerProgress - 1) < 0 {
                                updateStory(forward: false)
                            } else {
                                timerProgress = CGFloat(Int(timerProgress - 1))
                            }
                        }
                    
                    Rectangle()
                        .fill(.black.opacity(0.01))
                        .onTapGesture {
                            if (timerProgress + 1) > CGFloat(story.pages.count) {
                                updateStory()
                            } else {
                                timerProgress = CGFloat(Int(timerProgress + 1))
                            }
                        }
                }
                    .frame(height: proxy.size.height * 0.45)
                    .padding(.top, 65)
                , alignment: .top
            )
            .overlay(
                Button(action: {
                    storyViewModel.showStory = false
                }, label: {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 2, x: 1, y: 1)
                })
                .padding()
                .padding(.top, 20)
                , alignment: .topTrailing
            )
            .overlay(
                HStack(spacing: 5) {
                    ForEach(story.pages.indices, id: \.self) { index in
                        
                        GeometryReader { proxy in
                            
                            let width = proxy.size.width
                            let progress = timerProgress - CGFloat(index)
                            let perfectProgress = min(max(progress, 0), 1)
                            
                            Capsule()
                                .fill(.gray.opacity(0.5))
                                .overlay(
                                    Capsule()
                                        .fill(Color.mimoYellow500)
                                        .frame(width: width * perfectProgress)
                                    , alignment: .leading
                                )
                        }
                    }
                }
                .frame(height: 4)
                .padding()
                , alignment: .top
            )
            .overlay(
                VStack(spacing: 0) {
                    Divider()
                        .frame(minHeight: 1)
                        .background(Color.white.opacity(0.2))
                        .padding(.bottom, 16)
                        .padding(.horizontal, 20)
                    
                    HStack {
                        Spacer()

                        HStack(spacing: 10) {
                            
                            Button {
                                shareURL = URL(string: "https://mimometasharing.com/")
                            } label: {
                                ZStack {
                                    Color.white.opacity(0.1)
                                    
                                    Image(systemName: "arrowshape.turn.up.right")
                                        .resizable()
                                        .foregroundColor(Color.white)
                                        .frame(width: 24, height: 24)
                                }
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                            }

                            Button {
                                storyViewModel.like()
                            } label: {
                                ZStack {
                                    Color.white.opacity(0.1)

                                    Image(systemName: storyViewModel.isLiked() ? "heart.fill" : "heart")
                                        .resizable()
                                        .foregroundColor(storyViewModel.isLiked() ? Color.mimoYellow500 : Color.white)
                                        .frame(width: 20, height: 20)
                                }
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                            }
                            .disabled(storyViewModel.isLiked())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                , alignment: .bottom
            )
            .rotation3DEffect(getAngle(proxy: proxy),
                              axis: (x: 0, y: 1, z: 0),
                              anchor: proxy.frame(in: .global).minX > 0 ? .leading : .trailing,
                              perspective: 2.5)
        }
        .onAppear(perform: {
            withAnimation {
                timerProgress = 0
            }
        })
        .onReceive(timer) { _ in
            guard isTimerRunning else { return }
            
            if story.id == storyViewModel.currentStory {
                if timerProgress < CGFloat(story.pages.count) {
                    withAnimation {
                        timerProgress += 0.02
                    }
                } else {
                    updateStory()
                }
            }
            
            let index = min(Int(timerProgress), story.pages.count - 1)
            if self.currentIndex != index {
                self.currentIndex = index
                
                print("Story -> \(story.pages[index].title) ::::")
            }
        }
        .gesture(LongPressGesture(minimumDuration: 0.01)
            .sequenced(before: LongPressGesture(minimumDuration: .infinity))
                    .updating($isPressing) { value, state, transaction in
                        switch value {
                        case .second(true, nil):
                            state = true
                            isTimerRunning = false
                        case .first(true):
                            print("1111isPressinggg: \(value)")
                        default:
                            break
                        }
                    })
                .onChange(of: isPressing) { value in
                    if value == false {
                        isTimerRunning = true
                    }
                    
                    print("isPressinggg: \(value)")
                }
    }
    
    func getAngle(proxy: GeometryProxy) -> Angle {
        let progress = proxy.frame(in: .global).minX / proxy.size.width
        let rotationAngle: CGFloat = 45
        let degrees = rotationAngle * progress
        
        return Angle(degrees: Double(degrees))
    }
    
    func updateStory(forward: Bool = true) {
        let index = min(Int(timerProgress), story.pages.count - 1)
        let currentStory = self.story.pages[index]
        
        if !forward {
            if let first = storyViewModel.stories.value.first, first.id != story.id {
                let storyIndex = storyViewModel.stories.value.firstIndex(where: { $0.id == story.id }) ?? 0
                withAnimation {
                    storyViewModel.currentStory = storyViewModel.stories.value[storyIndex - 1].id
                }
            } else {
                withAnimation {
                    timerProgress = 0
                }
            }
            return
        }
        
        if let last = story.pages.last, last.number == currentStory.number {
            if let lastStory = storyViewModel.stories.value.last, lastStory.id == story.id {
                storyViewModel.showStory = false
//                timerProgress = 0
            } else {
                let storyIndex = storyViewModel.stories.value.firstIndex(where: { $0.id == story.id }) ?? 0
                withAnimation {
                    storyViewModel.currentStory = storyViewModel.stories.value[storyIndex + 1].id
                }
            }
        }
    }
}

extension View {
    func pressAction(onPress: @escaping (() -> Void), onRelease: @escaping (() -> Void)) -> some View {
        modifier(PressActions(onPress: {
            onPress()
        }, onRelease: {
            onRelease()
        }))
    }
}

struct PressActions: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 20)
                    .onChanged({ _ in
                        onPress()
                    })
                    .onEnded({ _ in
                        onRelease()
                    })
            )
    }
}

struct CustomGestureModifier: ViewModifier {
    var onRightTap: () -> Void
    var onLeftTap: () -> Void
    var onLongPressBegan: (() -> Void)
    var onLongPressEnded: () -> Void
    
    func body(content: Content) -> some View {
        content
            .overlay(
                CustomGestureRepresentable(
                    onRightTap: onRightTap,
                    onLeftTap: onLeftTap,
                    onLongPressBegan: onLongPressBegan,
                    onLongPressEnded: onLongPressEnded
                )
            )
    }
}

extension View {
    func customGestures(
        onRightTap: @escaping () -> Void,
        onLeftTap: @escaping () -> Void,
        onLongPressBegan: @escaping () -> Void,
        onLongPressEnded: @escaping () -> Void
    ) -> some View {
        self.modifier(CustomGestureModifier(
            onRightTap: onRightTap,
            onLeftTap: onLeftTap,
            onLongPressBegan: onLongPressBegan,
            onLongPressEnded: onLongPressEnded
        ))
    }
}
