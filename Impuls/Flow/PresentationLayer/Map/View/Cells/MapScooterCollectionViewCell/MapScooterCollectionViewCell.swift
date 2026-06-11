//
//  MapBikeCollectionViewCell.swift
//  MimoBike
//
//  Created by Vardan on 21.04.21.
//

import UIKit

protocol MapScooterCollectionViewCellDelegate: AnyObject {
    func didBookButtonTapped(cell: MapScooterCollectionViewCell)
    func didTakeScooterButtonTapped(cell: MapScooterCollectionViewCell)
}
class MapScooterCollectionViewCell: UICollectionViewCell {

    
    //MARK: - Outlets
    @IBOutlet weak var viewForQR: UIView!
    
    @IBOutlet weak var contentBGView: UIView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var viewForShadow: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var buttonContentView: UIView!
    
    @IBOutlet weak var qrLabel: UILabel!
    
    //MARK: - Variables
    
    weak var delegate: MapScooterCollectionViewCellDelegate?
    var scooterResult: ScooterResult?
    
    //MARK: - Life cycle

    override func awakeFromNib() {
        super.awakeFromNib()
        configureUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        buttonContentView.backgroundColor = .mimoBlackWith025alpha
    }
    
    //MARK: - Methods

    /// configure user interface
    func configureUI() {
        viewForQR.layer.borderColor = UIColor.mimoYellow100.cgColor
        viewForQR.layer.borderWidth = 1.0
        viewForQR.layer.cornerRadius = viewForQR.frame.height / 2
        buttonContentView.layer.cornerRadius = Constant.CornerRadius.cornerRadius19
        viewForShadow.addShadow(color: .mimoBlackWith025alpha)
        contentBGView.layer.cornerRadius = 12
    }
    
    func updateUI() {
//         self.scooterResult?.getLocationName(long: false, completed: { [weak self] (streetDescription) in
//             self?.locationLabel.text = streetDescription
//         })

//         self.timeLabel.text = scooterResult?.timePrettyPrinted()
        
        qrLabel.text = scooterResult?.qr
     }
    
    
    //MARK: - Methods
    
    @IBAction func joinButtonTapped(_ sender: UIButton) {
        //delegate?.didJoinButtonTapped(cell: self)
    }
    
}
