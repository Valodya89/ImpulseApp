//
//  MapJoinNowSheetViewController.swift
//  MimoBike
//
//  Created by Vardan on 20.04.21.
//

import UIKit

enum MapJoinNowSheetButtonsState {
    case join
    case bike
}

protocol MapJoinNowSheetViewControllerDelegate: AnyObject {
    func didTappedButton(state: MapJoinNowSheetButtonsState)
}

final class MapJoinNowSheetViewController: UIViewController, StoryboardInitializable {

    
    //MARK: - Outlets
    @IBOutlet private weak var joinNowView: UIView!
    @IBOutlet private weak var bikeContentView: UIView!
    @IBOutlet private weak var bikeView: UIView!
    
    
    //MARK: - Variables

    weak var delegate: MapJoinNowSheetViewControllerDelegate?
    //MARK: - Life cycles

    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
    }
    
    
    //MARK: - Methods

    ///configure user interface
    private func configureUI() {
        joinNowView.layer.cornerRadius = Constant.CornerRadius.cornerRadiusFromScreenWidth24
        
        bikeContentView.layer.cornerRadius = Constant.CornerRadius.cornerRadiusFromScreenWidth24
        bikeContentView.layer.borderWidth = 1
        bikeContentView.layer.borderColor = UIColor.mimoBlackWith025alpha.cgColor
        
        bikeView.layer.cornerRadius = Constant.CornerRadius.cornerRadiusFromScreenWidth20
    }
    

    //MARK: - Actions

    @IBAction func joinNowTapped(_ sender: UIButton) {
        delegate?.didTappedButton(state: .join)
    }
    
    @IBAction func bikeButtonTapped(_ sender: UIButton) {
        delegate?.didTappedButton(state: .bike)
    }
}
