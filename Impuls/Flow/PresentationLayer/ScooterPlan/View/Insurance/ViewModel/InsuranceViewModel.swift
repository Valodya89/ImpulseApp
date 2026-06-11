//
//  InsuranceViewModel.swift
//  MimoBike
//
//  Created by Yurka Babayan on 19.09.25.
//


//If your car's stolen or catches fire
//Claims made against you for people, passengers and their property.
//It may differ by policy, so check what you're covered for

import Foundation
import SwiftUI

class InsuranceViewModel: ObservableObject {
    private let network = SessionNetwork()
    
    @Published var termsCheckIsSelected: Bool = false {
        didSet {
            let language = StorageManager().fetch(key: .language, type: String.self)
            var URLString = URL(string: "https://prodservice.liga.am/uploads/ck/MimoBike_En.pdf")
            if language == "hy" {
                URLString = URL(string: "https://prodservice.liga.am/uploads/ck/MimoBike_Am.pdf")
            } else {
                URLString = URL(string: "https://prodservice.liga.am/uploads/ck/MimoBike_En.pdf")
            }
            
            if let url = URLString, termsCheckIsSelected {
                DispatchQueue.main.async {
                    UIApplication.shared.open(url)
                }
            }
        }
    }
    
    private var insurances: [InsuranceModel] = [
        InsuranceModel(text: "SCOOTER_insurance_benefit_1", url: "https://prodservice.liga.am/uploads/information-pages/items/documents/85/Personal_Accident_Insurance_TC_valid_28%E2%80%A406%E2%80%A42023_T638250846095599335.pdf"),
        InsuranceModel(text: "SCOOTER_insurance_benefit_2", url: "https://prodservice.liga.am/uploads/information-pages/items/documents/85/Personal_Accident_Insurance_TC_valid_28%E2%80%A406%E2%80%A42023_T638250846095599335.pdf"),
        InsuranceModel(text: "SCOOTER_insurance_benefit_3", url: "https://prodservice.liga.am/uploads/information-pages/items/documents/85/Personal_Accident_Insurance_TC_valid_28%E2%80%A406%E2%80%A42023_T638250846095599335.pdf"),
        InsuranceModel(text: "SCOOTER_insurance_benefit_4", url: "https://prodservice.liga.am/uploads/information-pages/items/documents/85/Personal_Accident_Insurance_TC_valid_28%E2%80%A406%E2%80%A42023_T638250846095599335.pdf")
    ]
    
    var attributes: [AttributedString] = []
    var attributesTermsText: AttributedString = ""
    
    init() {
        setupAttributedsData()
        attributesTermsText = setupAttributesTermsText(attribute: AttributedString("SCOOTER_insurance_terms_info".localized()))
    }
    
    func setupAttributedsData() {
        for insurance in insurances {
            attributes.append(setupAttributedString(attribute: AttributedString(insurance.text), url: insurance.url))
        }
    }
    
    func setupAttributedString(attribute: AttributedString, url: String) -> AttributedString {
        var string = attribute
        string.foregroundColor = .gray
        
        return string
    }
    
    func setupAttributesTermsText(attribute: AttributedString) -> AttributedString {
        let language = StorageManager().fetch(key: .language, type: String.self)
        var string = attribute
        string.foregroundColor = .gray
        if language == "hy" {
            string.link = URL(string: "https://prodservice.liga.am/uploads/ck/MimoBike_Am.pdf")
        } else {
            string.link = URL(string: "https://prodservice.liga.am/uploads/ck/MimoBike_En.pdf")
        }
        string.underlineStyle = .single
        
        return string
    }
    
    func activateInsurance(completion: @escaping (Result<InsuranceResponceModel, WalletRequestErrors>) -> Void) {
        
        network.request(with: URLBuilder(from: AuthAPI.activateInsurance)) { (result) in
            switch result {
            case .success(let data):
                guard let activateInsurance = MimoConverter<BaseResponseModel<InsuranceResponceModel>>.parseJson(data: data as Any) else {
                    completion(.failure(WalletRequestErrors.parseError))
                    return
                }
                if let content = activateInsurance.content, activateInsurance.statusCode == 200 {
                    print("activateInsurance === \(activateInsurance)")
                    completion(.success(content))
                } else {
                    completion(.failure(.custom(message: activateInsurance.message)))
                }
            case .failure(let error):
                completion(.failure(.internalError))
            }
        }
    }   
}
