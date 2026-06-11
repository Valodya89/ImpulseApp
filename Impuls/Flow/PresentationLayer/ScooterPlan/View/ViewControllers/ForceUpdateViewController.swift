//
//  ForceUpdateViewController.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 30.09.22.
//

import UIKit

class ForceUpdateViewController: UIViewController, StoryboardInitializable {

    @IBOutlet weak var updateButton: UILocalizedButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        updateButton.layer.cornerRadius = updateButton.frame.height / 2
    }
    
    @IBAction func updateAction(_ sender: UILocalizedButton) {
        guard let appURL = URL(string: "https://apps.apple.com/us/app/mimo-meta-sharing/id1576701754") else { return }
        UIApplication.shared.open(appURL, options: [:], completionHandler: { _ in
            // Handle
        })
    }
    
}
