//
//  MimoUserCheckModel.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 03.06.21.
//

import Foundation

enum MimoUserCheckModel {
    case noSuchUser
    case isMimoUser(ContactsListModel)
    case error
    
    init(model: BaseResponseModel<UserResponse>) {
        let statusMessage = MimoUserStatusMessages(rawValue: model.message)
        
        switch statusMessage {
        case .noSuchUser:
            if model.statusCode == 404 {
                self = .noSuchUser
                
                return
            }
            
            self = .error
        case .success:
            if model.statusCode == 200 {
                guard let content = model.content else {
                    self = .error
                    
                    return
                }
                
                self = .isMimoUser(ContactsListModel(result: content))
                
                return
            }
            
            fallthrough
        default:
            self = .error
        }
    }
    
    enum MimoUserStatusMessages: String {
        case noSuchUser = "ACCOUNTS_no_such_user"
        case success = "SUCCESS"
    }
}
