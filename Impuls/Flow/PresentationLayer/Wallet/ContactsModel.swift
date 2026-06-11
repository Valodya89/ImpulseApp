//
//  ContactsModel.swift
//  MimoBike
//
//  Created by Vardan on 21.05.21.
//

import UIKit
import Contacts

class ContactsModel {
    let firstName: String
    let lastName: String
    var identifier: String?
    let profilePicture: UIImage?
    var storedContact: CNMutableContact?
    var phoneNumberField: (CNLabeledValue<CNPhoneNumber>)?
    var phoneNumber: String?
    
    init(firstName: String, lastName: String, profilePicture: UIImage?, phoneNumber: String? = nil){
        self.firstName = firstName
        self.lastName = lastName
        self.profilePicture = profilePicture
        self.phoneNumber = phoneNumber
    }
}

extension ContactsModel: Equatable {
    static func ==(lhs: ContactsModel, rhs: ContactsModel) -> Bool{
        return lhs.firstName == rhs.firstName &&
            lhs.lastName == rhs.lastName &&
            lhs.profilePicture == rhs.profilePicture
    }
}

extension ContactsModel {
    var contactValue: CNContact {
        let contact = CNMutableContact()
        contact.givenName = firstName
        contact.familyName = lastName
        if let profilePicture = profilePicture {
            let imageData = profilePicture.jpegData(compressionQuality: 1)
            contact.imageData = imageData
        }
        if let phoneNumberField = phoneNumberField {
            contact.phoneNumbers.append(phoneNumberField)
        }
        return contact.copy() as! CNContact
    }
    
    convenience init?(contact: CNContact) {
        let firstName = contact.givenName
        let lastName = contact.familyName
        var profilePicture: UIImage?
        if let imageData = contact.imageData {
            profilePicture = UIImage(data: imageData)
        }
        self.init(firstName: firstName, lastName: lastName, profilePicture: profilePicture)
        if let contactPhone = contact.phoneNumbers.first {
            phoneNumberField = contactPhone
            phoneNumber = contactPhone.value.stringValue
        }
    }
}


class ContactsListModel: Decodable, Hashable {
    
    let receiverName: String?
    let receiverSurname: String?
    let receiverAvatar: AvatarResponse?
    let amount: Double?
    var receiverId: String?
    
    init(result: UserResponse) {
        self.receiverName = result.name
        self.receiverSurname = result.surname
        self.receiverAvatar = result.avatar
        self.amount = 0.0
        self.receiverId = ""
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(receiverId ?? "")
    }
    
    static func == (lhs: ContactsListModel, rhs: ContactsListModel) -> Bool {
        return lhs.receiverId == rhs.receiverId
    }
    
    func getName() -> String {
        let info = (receiverName ?? "") + " " + (receiverSurname ?? "")
        
        if info.isEmpty {
            return receiverId ?? ""
        }
        
        return info
    }
}


