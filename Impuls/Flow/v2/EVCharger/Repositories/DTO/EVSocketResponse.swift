//
//  EVSocketResponse.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 8/4/25.
//

import Foundation

struct EVSocketResponse: Decodable {
    let id: String
    let payload: EVStateMessagedDTO
}
