//
//  CameraView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 23.05.24.
//

import SwiftUI

struct CameraView: View {
    
    @Binding var image: Image?
    
    var body: some View {
        GeometryReader { geometry in
            if let image = image {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
}
