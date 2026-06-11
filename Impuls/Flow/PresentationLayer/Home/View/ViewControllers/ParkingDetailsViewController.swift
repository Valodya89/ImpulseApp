//
//  ParkingDetailsViewController.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 23.01.23.
//

import UIKit

class ParkingDetailsViewController: UIViewController {

    @IBOutlet weak var popupView: UIView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var popupOKButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    func setupUI() {
        popupView.layer.cornerRadius = 12
        popupView.layer.borderWidth = 2
        popupView.layer.borderColor = UIColor.mimoYellow500.cgColor
        
        popupOKButton.layer.cornerRadius = popupOKButton.frame.height / 2
    }
    
    @IBAction func didTapOK(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
}
