//
//  SpeedChargeCollectionViewCell.swift
//  MimoBike
//
//  Created by Karen Galoyan on 7/17/22.
//

import UIKit

final public class SpeedChargeCollectionViewCell: UICollectionViewCell {

    // MARK: Outlets
    @IBOutlet private weak var selectedView: UIView!
    @IBOutlet private weak var speedLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    
    // MARK: Properties
    public static let cellNibName = UINib(nibName: "SpeedChargeCollectionViewCell", bundle: nil)
    public static let cellIdentifier = "SpeedChargeCollectionViewCell"
    
    // MARK: View Lifecycle
    public override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    // MARK: Methods
    func setData(speedTariff: SpeedTariff) {
        selectedView.backgroundColor = speedTariff.isSelected ? .white : UIColor(named: "mimoGrayLight")
        selectedView.layer.cornerRadius = 6
        selectedView.layer.borderColor = UIColor(named: "mimoYellow500")?.cgColor
        selectedView.layer.borderWidth = speedTariff.isSelected ? 1 : 0
        selectedView.backgroundColor = speedTariff.isSelected ? .selectedSpeed : .unSelectedSpeed
        speedLabel.text = speedTariff.title?.replacingOccurrences(of: "km/h", with: "SCOOTER_global_km_hour".localized())
    }
}
