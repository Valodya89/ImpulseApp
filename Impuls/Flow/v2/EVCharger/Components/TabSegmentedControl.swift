//
//  TabSegmentedControl.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 2/26/25.
//

import SwiftUI

struct TabSegmentedControl: View {
    @Binding var selected: Int

    let pages: [(title: String, contentView: AnyView)]
    
    @State private var proxy: ScrollViewProxy?
    @Namespace var name
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                Capsule()
                    .fill(Color.evStroke)
                    .frame(height: 2)
                
                SegmentedControlOptionsView
            }
            .padding(.horizontal, 16)
            
            SegmentedContentView
                .padding(.top, 20)
        }
    }
    
   private var SegmentedControlOptionsView: some View {
        HStack(spacing: 0) {
            ForEach(Array(zip(pages.indices, pages)), id: \.0) { index, page in
                Button {
                    withAnimation(.bouncy) {
                        selected = index
                        proxy?.scrollTo(index)
                    }
                } label: {
                    VStack(spacing: 10) {
                        Text(page.title)
                            .padding(.horizontal, 20)
                            .font(.robotoRegular14)
                            .foregroundColor(Color.evText9)
                            .opacity(selected == index ? 1 : 0.6)
                        
                        ZStack {
                            Capsule()
                                .fill(.clear)
                                .frame(height: 2)
                            if selected == index {
                                Capsule()
                                    .fill(Color.evbrandCyan80)
                                    .frame(height: 2)
                                    .matchedGeometryEffect(id: "Tab", in: name)
                            }
                        }
                    }
                    .fixedSize(horizontal: true, vertical: false)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer(minLength: 0)
        }
    }
    
    private var SegmentedContentView: some View {
        pages[selected].contentView
    }
}
