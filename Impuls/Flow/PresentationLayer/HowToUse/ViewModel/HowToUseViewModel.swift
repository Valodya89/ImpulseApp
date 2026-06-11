//
//  HowToUseViewModel.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/4/21.
//

import Foundation

struct HowToUseViewModel {
    
    func getUrl(completion: (Result<URL, Error>) -> ()) {
        completion(.success(URL(string: "https://www.youtube.com/watch?v=tVNFj9CWQdM")!))
    }
}
