//
//  HomeCongratulationSheetViewController.swift
//  MimoBike
//
//  Created by Vardan on 20.05.21.
//

import UIKit

protocol HomeCongratulationSheetViewControllerDelegate: AnyObject {
    func didTappedClose()
}

class HomeCongratulationSheetViewController: BaseViewController, StoryboardInitializable {

    
    //MARK: - Outlets
    
    @IBOutlet weak var minuteFreeLabel: UILabel!
    
    
    //MARK: - Variables
    
    var delegate: HomeCongratulationSheetViewControllerDelegate?
    
    
    //MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
    }

    
    //MARK: - Methods
    
    func configureUI() {
        minuteFreeLabel.colorString(text: minuteFreeLabel.text, coloredText: ["10 minute Free"], color: .mimoBlackWith075alpha, font: UIFont(name: "Roboto-Bold", size: 15)!)
    }
    
    
    @IBAction func closeButtonTaped(_ sender: UIButton) {
        delegate?.didTappedClose()
    }
}
