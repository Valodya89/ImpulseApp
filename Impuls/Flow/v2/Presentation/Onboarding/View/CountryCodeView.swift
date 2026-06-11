//
//  CountryCodeView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 17.09.23.
//

import Foundation
import SwiftUI

struct CountryCodeView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UINavigationController
    
    @Binding var code: CountryCodeResponse?
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let vc = UIStoryboard(name: "CountryCode", bundle: nil).instantiateViewController(withIdentifier: "CountryCodeViewController") as! CountryCodeViewController
        vc.delegate = context.coordinator
        
        return UINavigationController(rootViewController: vc)
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        
    }
    
    func makeCoordinator() -> CountryCodeCoordinator {
        CountryCodeCoordinator(code: $code)
    }
}

class CountryCodeCoordinator: CountryCodeViewControllerDelegate {
    
    @Binding var code: CountryCodeResponse?
    
    init(code: Binding<CountryCodeResponse?>) {
        _code = code
    }
    
    func didSelectCountry(_ country: CountryCodeResponse) {
        code = country
    }
}
