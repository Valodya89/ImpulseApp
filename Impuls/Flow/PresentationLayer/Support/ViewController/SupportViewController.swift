//
//  SupportViewController.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/4/21.
//

import UIKit

final class SupportViewController: UIViewController, StoryboardInitializable {
    
    let supportViewModel = SupportViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func call(_ sender: UIButton) {
        supportViewModel.call(phoneNumber: "+79911005639")
    }
    
    @IBAction func informProblem(_ sender: UIButton) {
        let informProblemViewController = ImportProblemViewController.initFromStoryboard(name: Constant.Storyboards.account)
        
        self.navigationController?.pushViewController(informProblemViewController, animated: true)
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
