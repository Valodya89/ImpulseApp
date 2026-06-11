//
//  LanguageViewController.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/4/21.
//

import UIKit

class LanguageViewController: BaseViewController {
    
    let languageViewModel = LanguageViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setup()
    }

    func setup() {
        
        languageLabel.text = language.name
        flagImageView.image = UIImage(data: language.flag)
    }
}
