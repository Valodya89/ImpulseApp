//
//  ImageDto.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 28.06.24.
//

import Foundation

struct ImageDto: Decodable {
    let id: String?
    let node: String?
    let url: URL?
}

extension ImageDto {
    var imageURL: URL? {
        if let url {
            return url
        } else {
            guard let node, let id, let token = KeychainManager().getAccessToken() else { return nil }
            return URL(string: "https://\(node).impulsepower.ru/files?id=\(id)&token=\(token)")
        }
    }
}
