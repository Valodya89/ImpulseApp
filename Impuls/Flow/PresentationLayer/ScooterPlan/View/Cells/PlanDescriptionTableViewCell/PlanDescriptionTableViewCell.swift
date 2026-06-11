//
//  PlanDescriptionTableViewCell.swift
//  MimoBike
//
//  Created by Karen Galoyan on 7/18/22.
//

import UIKit

final public class PlanDescriptionTableViewCell: UITableViewCell {

    // MARK: Outlets
    @IBOutlet private weak var planImageView: UIImageView!
    @IBOutlet private weak var planTitleLabel: UILabel!
    @IBOutlet private weak var planDescriptionLabel: UILabel!
    
    // MARK: Properties
    public static let cellNibName = UINib(nibName: "PlanDescriptionTableViewCell", bundle: nil)
    public static let cellIdentifier = "PlanDescriptionTableViewCell"
    
    // MARK: View Lifecycle
    public override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    public override func prepareForReuse() {
        planImageView.image = nil
        planTitleLabel.text = ""
        planDescriptionLabel.text = ""
    }
    
    // MARK: Methods
    func setData(billingTarif: BillingTarif,  speedTariff: SpeedTariff) {
        planImageView.image = nil
        planTitleLabel.text = ""
        planDescriptionLabel.text = ""
        var desc = ""
//        switch billingTarif.title ?? "" {
//        case "For 1 hour":
//            planTitleLabel.text = "SCOOTER_global_for_one_hour".localized()
//            desc = "SCOOTER_global_for_one_hour_price".localized()
//        case "Minute by minute":
//            planTitleLabel.text = "SCOOTER_global_minute_by_minute".localized()
//            desc = "SCOOTER_global_minute_by_minute_price".localized()
//        case "Do not sit":
//            planTitleLabel.text = "SCOOTER_global_do_not_sit".localized()
//            desc = "SCOOTER_global_minute_by_minute_price".localized()
//        default:
//            planTitleLabel.text = "SCOOTER_global_minute_by_minute".localized()
//            desc = "SCOOTER_global_do_not_sit_price".localized()
//        }
        planTitleLabel.text = billingTarif.title ?? ""
        planDescriptionLabel.text = (billingTarif.description ?? "").replacingOccurrences(of: "${price}", with: billingTarif.mode == "MINUTE_BY_MINUTE" ? "\(speedTariff.price ?? 0.0)" : "\(billingTarif.price ?? 0.0)")
        
        guard let avatarId = billingTarif.logo?.id,
              let node = billingTarif.logo?.node else { return }
        let avatar = "https://\(node).impulsepower.ru/files?id=\(avatarId)&token="
        self.planImageView.setImage(avatar, defaultImage: #imageLiteral(resourceName: "ic_default_avatar"))
    }
}
