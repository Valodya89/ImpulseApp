//
//  ChoosePlanCollectionViewCell.swift
//  MimoBike
//
//  Created by Karen Galoyan on 7/18/22.
//

import UIKit

final public class ChoosePlanCollectionViewCell: UICollectionViewCell {

    // MARK: Outlets
    @IBOutlet private weak var selectedView: UIView!
    @IBOutlet private weak var planTitleLabel: UILabel!
    @IBOutlet private weak var planImageView: UIImageView!
    @IBOutlet private weak var planPriceLabel: UILabel!
    
    // MARK: Properties
    public static let cellNibName = UINib(nibName: "ChoosePlanCollectionViewCell", bundle: nil)
    public static let cellIdentifier = "ChoosePlanCollectionViewCell"
    
    // MARK: View Lifecycle
    public override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    // MARK: Methods
    func setData(billingTarif: BillingTarif, price: String) {
        print("billingTarif = \(billingTarif)")
        selectedView.backgroundColor = billingTarif.isSelected ? .white : UIColor(named: "mimoGrayLight")
        selectedView.layer.cornerRadius = 16
        selectedView.layer.borderColor = UIColor(named: "mimoYellow500")?.cgColor
        selectedView.layer.borderWidth = billingTarif.isSelected ? 1 : 0
        selectedView.backgroundColor = billingTarif.isSelected ? .selectedSpeed : .unSelectedSpeed
        planTitleLabel.text = billingTarif.title ?? ""
        print("planTitleLabel.text = \(planTitleLabel.text)")
//        switch billingTarif.mode ?? "" {
//        case "For 1 hour":
//            planTitleLabel.text = "SCOOTER_global_for_one_hour".localized()
//        case "Minute by minute":
//            planTitleLabel.text = "SCOOTER_global_minute_by_minute".localized()
//        case "Do not sit":
//            planTitleLabel.text = "SCOOTER_global_do_not_sit".localized()
//        default:
//            planTitleLabel.text = "SCOOTER_global_minute_by_minute".localized()
//        }
        
        planPriceLabel.text = billingTarif.priceName?.replacingOccurrences(of: "${price}", with: price == "-" ? "\(billingTarif.price ?? 0.0)" : price).replacingOccurrences(of: "min", with: "MOBILE_guest_map_minutes".localized())
        
        guard let avatarId = billingTarif.logo?.id,
              let node = billingTarif.logo?.node else { return }
        let avatar = "https://\(node).impulsepower.ru/files?id=\(avatarId)&token="
        self.planImageView.setImage(avatar, defaultImage: #imageLiteral(resourceName: "ic_default_avatar"))
    }
}
