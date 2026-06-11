//
//  Story.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 25.12.23.
//

import Foundation

struct Story: Decodable, Identifiable {
    let id: String
    let name: String
    var like: Bool
    var order: Int?
    let pages: [StoryPage]
}

struct StoryPage: Decodable {
    let number: Int
    let content: String
    let options: [String]
    let selectedOptions: [String]
    let title: String
    let type: StoryType
    let background: ImageObj?
    let logo: ImageObj?
    let url: String?
    let urlButtonName: String?
}


enum StoryType: String, Decodable {
    case link = "LINK"
    case questionnaire = "QUESTIONNAIRE"
}
