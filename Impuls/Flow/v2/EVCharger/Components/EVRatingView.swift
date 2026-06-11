//
//  EVRatingView.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 2/26/25.
//

import SwiftUI

struct EVRatingView: View {
    let maxRating: Int
    let rating: Int
    
    init(maxRating: Int, rating: Int) {
        self.maxRating = max(0, maxRating)
        self.rating =  min(max(0, rating), maxRating)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<maxRating, id: \.self) { index in
                Image(index < rating ? "review_flash" : "review_flash_inactive")
            }
        }
    }
}
