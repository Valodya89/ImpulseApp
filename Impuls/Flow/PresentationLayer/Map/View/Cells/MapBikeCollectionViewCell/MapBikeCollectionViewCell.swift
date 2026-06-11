//
//  MapBikeCollectionViewCell.swift
//  MimoBike
//
//  Created by Vardan on 21.04.21.
//

import UIKit

protocol MapBikeCollectionViewCellDelegate: AnyObject {
    func didJoinButtonTapped(cell: MapBikeCollectionViewCell)
}
class MapBikeCollectionViewCell: UICollectionViewCell {

    
    //MARK: - Outlets
    
    @IBOutlet weak var contentBGView: UIView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var viewForShadow: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var buttonContentView: UIView!
    
    
    //MARK: - Variables
    
    weak var delegate: MapBikeCollectionViewCellDelegate?
    var bikeResult: BikeResult?
    
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
        buttonContentView.layer.cornerRadius = Constant.CornerRadius.cornerRadius19
        viewForShadow.addShadow(color: .mimoBlackWith025alpha)
        contentBGView.layer.cornerRadius = 12
    }
    
    func updateUI() {
//         self.bikeResult?.getLocationName(long: false, completed: { [weak self] (streetDescription) in
//             self?.locationLabel.text = streetDescription
//         })
//
//         self.timeLabel.text = bikeResult?.timePrettyPrinted()
     }
    
    
    //MARK: - Methods
    
    @IBAction func joinButtonTapped(_ sender: UIButton) {
        delegate?.didJoinButtonTapped(cell: self)
    }
    
}
