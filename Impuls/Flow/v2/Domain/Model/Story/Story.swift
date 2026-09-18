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
    
    private enum CodingKeys: String, CodingKey {
        case number, content, options, selectedOptions, title, type, background, logo, url, urlButtonName
    }
    
    /// A LINK page comes with `content`, `title` and `options` as JSON null;
    /// decoding them as required strings used to fail the whole stories
    /// response, so no story ever reached the home screen.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        number = try container.decodeIfPresent(Int.self, forKey: .number) ?? 0
        content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
        options = try container.decodeIfPresent([String].self, forKey: .options) ?? []
        selectedOptions = try container.decodeIfPresent([String].self, forKey: .selectedOptions) ?? []
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        type = try container.decodeIfPresent(StoryType.self, forKey: .type) ?? .link
        background = try container.decodeIfPresent(ImageObj.self, forKey: .background)
        logo = try container.decodeIfPresent(ImageObj.self, forKey: .logo)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        urlButtonName = try container.decodeIfPresent(String.self, forKey: .urlButtonName)
    }
}


enum StoryType: String, Decodable {
    case link = "LINK"
    case questionnaire = "QUESTIONNAIRE"
}
