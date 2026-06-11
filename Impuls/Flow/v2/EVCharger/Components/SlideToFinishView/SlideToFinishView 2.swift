//
//  SlideToFinishView.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 11.04.25.
//

import SwiftUI

struct SlideToFinishView: View {
    
    private let minWidth: CGFloat
    @State private var width: CGFloat
    @State private var viewWidth: CGFloat
    @Binding var isLoading: Bool
    var onSlideComplete: Action
    
    init(isLoading: Binding<Bool>, onSlideComplete: @escaping Action) {
        self._isLoading = isLoading
        self.onSlideComplete = onSlideComplete
        self.minWidth = 72
        self.width = minWidth
        self.viewWidth = .infinity
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .stroke(Color.evbrandCyan80.opacity(0.4), lineWidth: 3)
                .background(
                    GeometryReader { geometry in
                        Color.evbrandCyan80.opacity(0.2)
                            .onAppear {
                                viewWidth = geometry.size.width
                            }
                    }
                )
                .overlay(
                    Text("EV_CHARGER_slide_to_finish".localized())
                        .padding(.leading, 76)
                        .foregroundColor(Color.evbrandCyan80)
                )
                .frame(height: 48)

            Color(.evbrandCyan80)
                .frame(maxWidth: width)
                .gesture(
                    DragGesture()
                        .onChanged { drag in
                            guard !isLoading else { return }
                            
                            if drag.location.x >= minWidth {
                                width = drag.location.x
                            }
                        }
                        .onEnded { _ in
                            guard !isLoading else { return }
                            
                            withAnimation(.easeInOut(duration: 0.03)) {
                                if width > viewWidth - 100 {
                                    width = viewWidth
                                    
                                    // Haptic feedback
                                    let generator = UINotificationFeedbackGenerator()
                                    generator.notificationOccurred(.success)
                                    
                                    onSlideComplete()
                                } else {
                                    width = minWidth
                                }
                            }
                        }
                )
                .clipShape(Capsule())
                .overlay(slack, alignment: .trailing)
                .frame(height: 45)
                .padding(.horizontal, 1.5)

        }
        .clipShape(Capsule())
        .overlay {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(width: 24, height: 24)
            }
        }
    }
    
    @ViewBuilder
    var slack: some View {
        if width != viewWidth {
            Image(systemName: "arrow.right")
                .foregroundColor(.white)
                .font(.robotoBold24)
                .padding(.trailing, 20)
        }
    }
}

#Preview {
    SlideToFinishView(isLoading: .constant(false), onSlideComplete: {})
}
