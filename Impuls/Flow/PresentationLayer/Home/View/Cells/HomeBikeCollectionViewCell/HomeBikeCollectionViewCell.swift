//
//  HomeBikeCollectionViewCell.swift
//  MimoBike
//
//  Created by Vardan on 04.05.21.
//

import UIKit

protocol HomeBikeCollectionViewCellDelegate: AnyObject {
    func didJoinButtonTapped(cell: HomeBikeCollectionViewCell)
}

class HomeBikeCollectionViewCell: UICollectionViewCell {
    
    
    //MARK: - Outlets
    
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var contentBGView: UIView!
    @IBOutlet weak var viewForShadow: UIView!
    @IBOutlet weak var buttonContentView: UIView!
    
    
    //MARK: - Variables
    weak var delegate: HomeBikeCollectionViewCellDelegate?
    
    var bikeResult: BikeResult?
    
    //MARK: - Life cycle

    override func awakeFromNib() {
        super.awakeFromNib()
        configureUI()
    }

    override func prepareForReuse() {
        self.timeLabel.text = ""
        self.locationLabel.text = ""
        buttonContentView.backgroundColor = .mimoBlackWith025alpha
        self.bikeResult = nil
        super.prepareForReuse()
    }
    
    
    //MARK: - Methods

    /// configure user interface
    func configureUI() {
        buttonContentView.layer.cornerRadius = Constant.CornerRadius.cornerRadius19
        viewForShadow.addShadow(color: .mimoBlackWith025alpha)
        contentBGView.layer.cornerRadius = 12
    }
    
    func updateUI(bikeResult: BikeResult?) {
        self.bikeResult = bikeResult
//        self.bikeResult?.setLocationName(long: false, in: locationLabel)
//        self.timeLabel.text = bikeResult?.timePrettyPrinted()
    }
    
    
    //MARK: - Methods
    
    @IBAction func joinButtonTapped(_ sender: UIButton) {
        
        delegate?.didJoinButtonTapped(cell: self)
    }
    
}

extension Array {
    subscript(optional Index: Index) -> Element? {
        if self.indices.contains(Index) {
            return self[Index]
        }
        return nil
    }
}
