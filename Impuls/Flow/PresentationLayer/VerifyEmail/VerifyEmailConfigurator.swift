//
//  VerifyEmailConfigurator.swift
//  MimoBike
//
//  Created by Dose on 6/4/21.
//

import UIKit

struct VerifyEmailConfigurator {
    
    static func config(with email: String?) -> UIViewController {
        
        let controller = VerifyEmailViewController.initFromStoryboard(name: "VerifyEmail")
        
   
        controller.currentEmail = email
        
        return controller
    }
    
}
