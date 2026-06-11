//
//  GuideDTO.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 3/15/25.
//

import Foundation

struct GuideDTO: Decodable {
    let title: String
    let slides: [SlideDTO]
    
    struct SlideDTO: Decodable {
        let title: String
        let description: String
        let image: MediaDTO
        let sort: Int
    }
}
