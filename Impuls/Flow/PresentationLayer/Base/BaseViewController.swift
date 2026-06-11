//
//  BaseViewController.swift
//  MimoBike
//
//  Created by Vardan on 20.04.21.
//

import UIKit

class BaseViewController: UIViewController {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.isHidden = true
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    deinit {
        print("deinit - \(String(describing: self))")
    }
}
