//
//  MediaDTO.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 3/15/25.
//

import Foundation

struct MediaDTO: Decodable {
    let id: String
    let type: String
    let url: URL
}
