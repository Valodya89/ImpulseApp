//
//  GatewayCell.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 13.10.22.
//

import UIKit
import SDWebImage

class GatewayCell: UITableViewCell {

    @IBOutlet weak var icone: UIImageView!
    
    var gateway: GatewayModel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
//        icone.addShadow(color: .mimoYellow500)
    }

    func setData(gateway: GatewayModel) {
        self.gateway = gateway
        guard let avatarId = gateway.image?.id,
              let node = gateway.image?.node else { return }
        let avatar = "https://\(node).impulsepower.ru/files?id=\(avatarId)&token="
        self.icone.setImage(avatar, defaultImage: #imageLiteral(resourceName: "card_all"))
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
