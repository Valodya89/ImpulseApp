//
//  InAppWebView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 01.05.24.
//

import SwiftUI

struct InAppWebView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    let url: URL
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .foregroundColor(.black)
                            .frame(width: 18, height: 18)
                            .padding(8)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 15)
            }
            .frame(height: 54)
            
            ZStack {
                WebView(url: url)
            }
        }
    }
}
