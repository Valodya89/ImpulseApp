//
//  APIProtocol.swift
//  MimoBike
//
//  Created by Albert on 15.05.21.
//

import UIKit

protocol APIProtocol {
    var base: String { get }
    var path: String { get }
    var header: [String: String] { get }
    var query: [String: String] { get }
    var body: [String: Any]? { get }
    var bodyString: String? { get }
    var formData: MultipartFormData? { get }
    var method: RequestMethod { get }
}

protocol ImageUplaoder: APIProtocol {
    var image: UIImage? { get }
}

protocol MultipyImageLoad: APIProtocol {
    var images: [(key: String, UIImage)] { get }
}
