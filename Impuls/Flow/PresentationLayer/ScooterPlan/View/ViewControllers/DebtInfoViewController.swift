//
//  DdebtInfoViewController.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 21.08.22.
//

import UIKit

protocol DebtInfoViewControllerDelegate:  AnyObject {
    func didClose()
}

class DebtInfoViewController: UIViewController, StoryboardInitializable {

    
    @IBOutlet weak var bikeScooterImage: UIImageView!
    @IBOutlet weak var hiFriendLbl: UILabel!
    @IBOutlet weak var debtDescriptionLbl: UILabel!
    @IBOutlet weak var replanishBtn: UIButton!
    
    weak var delegate: DebtInfoViewControllerDelegate?
    var errorDescription: String = "" {
        didSet {
            debtDescriptionLbl.text = errorDescription
        }
    }
    
    var isShowOK: Bool = false {
        didSet  {
            replanishBtn.isHidden = isShowOK
        }
    }
    
    var isBike: Bool = false {
        didSet {
            bikeScooterImage.image = UIImage(named: isBike ? "Mimo_bike_New" : "Mimo_scooter_New")
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        configuureUI()
    }
    
    func configuureUI() {
        replanishBtn.layer.cornerRadius = replanishBtn.frame.height / 2
    }

    @IBAction func replanishAction(_ sender: UIButton) {
        delegate?.didClose()
    }

    @IBAction func closePageAction(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
}
