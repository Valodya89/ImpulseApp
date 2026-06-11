//
//  IconTitleView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 07.05.24.
//

import SwiftUI
import Kingfisher

struct IconTitleView: View {
    
    let title: String
    let image: String?
    let imageURL: URL?
    
    init(title: String, image: String? = nil, imageURL: URL? = nil) {
        self.title = title
        self.image = image
        self.imageURL = imageURL
    }
    
    var body: some View {
        HStack(spacing: 10) {
            if let image {
                Image(image)
                    .resizable()
                    .frame(width: 32, height: 32)
                    .scaledToFit()
                    .padding(.leading, 14)
            }
            
            if let imageURL {
                KFImage(imageURL)
                    .resizable()
                    .frame(width: 32, height: 32)
                    .scaledToFit()
                    .padding(.leading, 14)
            }
            
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.black)
                .padding(.leading, (image == nil && imageURL == nil) ? 14 : 0)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .resizable()
                .foregroundColor(.black)
                .frame(width: 8, height: 12)
                .padding(.trailing, 20)
        }
        .frame(maxHeight: .infinity)
        .roundedBorderMedium()
    }
}
