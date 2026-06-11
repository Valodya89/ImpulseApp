//
//  NewsObject.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 12.09.22.
//

import Foundation

struct NewsObject: Codable {

    let id: String
    let title: String
    let content: String
    let image: ImageObj
}

struct ImageObj: Codable {
    let id: String
    let node: String
}

extension ImageObj {
    var imageURL: URL? {
        guard let token = KeychainManager().getAccessToken() else { return nil }
        return URL(string: "https://\(node).impulsepower.ru/files?id=\(id)&token=\(token)")
    }
}
