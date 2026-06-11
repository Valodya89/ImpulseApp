//
//  OrderCardViewModel.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/5/21.
//

import Foundation

struct OrderCardError: Error {
    let errorDescription: String
}

struct OrderCardViewModel {
    
    let sessionNetwork = SessionNetwork()
    
    func orderCard(address: String?, birthday: String?, email: String?, passportImage: UIImage?, scn: String?, phone: String, completion: @escaping (Result<Void, OrderCardError>) -> ()) {
        let emailValidator = Validator(data: email)
            .notEmpty(errorMessage: "Email can not be empty")
            .isValidEmail()
            .validate()
        
        let imageBase64 = passportImage?.resizeImage(targetSize: CGSize(width: 200, height: 200)).pngData()?.base64EncodedString()
        guard emailValidator.isValid else {
            return completion(.failure(.init(errorDescription: "Email is not valid")))
        }
        
        guard let birthDay = birthday, !birthDay.isEmpty else {
            return completion(.failure(.init(errorDescription: "Birthday can not be empty")))
        }
        
        let birthdayDate = DateHelper.convertDateStringToDateObject(dateString: birthDay, pattern: "dd-MM-yyyy")

        guard let unwrapDate = birthdayDate else {
            return completion(.failure(.init(errorDescription: "Birthday date is invalide. Please fill with dd-mm-yyyy format")))
        }
        
        let unwrapDateString = unwrapDate.toString(format: .custom("dd-MM-yyyy"))
        guard let address = address, !address.isEmpty else {
            return completion(.failure(.init(errorDescription: "Address can not be empty")))
        }
        
        guard let pass64 = imageBase64, !pass64.isEmpty else {
            return completion(.failure(.init(errorDescription: "Passport image can not be empty")))
        }
        
        guard let scn = scn, !scn.isEmpty else {
            return completion(.failure(.init(errorDescription: "Social card number can not be empty")))
        }
        
        sessionNetwork.request(with: URLBuilder(from: AuthAPI.orderCard(address: address, birthday: unwrapDateString, email: email!, socialCard: scn, passportImageBase64: pass64, phone: phone))) { (result) in
            switch result {
            case .failure(let error):
                completion(.failure(.init(errorDescription: error.localizedDescription)))
            case .success(let data):
                let baseResponse = try? JSONDecoder().decode(BaseResponseModel<EmptyResponseModel>.self, from: data)
                
                if baseResponse?.statusCode == 200 {
                    completion(.success(()))
                } else {
                    completion(.failure(.init(errorDescription: "Failed to order card")))
                }
                
            }
        }
    }
}
