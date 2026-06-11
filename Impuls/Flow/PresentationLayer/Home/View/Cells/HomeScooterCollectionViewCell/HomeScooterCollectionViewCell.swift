//
//  HomeBikeCollectionViewCell.swift
//  MimoBike
//
//  Created by Vardan on 04.05.21.
//

import UIKit

protocol HomeScooterCollectionViewCellDelegate: AnyObject {
    func didBookNowButtonTapped(cell: HomeScooterCollectionViewCell)
    func didTakeScooterButtonTapped(cell: HomeScooterCollectionViewCell)
}

class HomeScooterCollectionViewCell: UICollectionViewCell {
    
    
    //MARK: - Outlets
    @IBOutlet weak var viewForQR: UIView!
    @IBOutlet weak var scooterName: UILabel!
    @IBOutlet weak var batareyIcon: UIImageView!
    @IBOutlet weak var persentageLabel: UILabel!
    @IBOutlet weak var timeKMLabel: UILabel!
    
    @IBOutlet weak var contentBGView: UIView!
    @IBOutlet weak var viewForShadow: UIView!
    @IBOutlet weak var buttonContentView: UIView!
    @IBOutlet weak var bokkeButtone: UIButton!
    @IBOutlet weak var bookNowLabel: UILocalizedLabel!
    @IBOutlet weak var takeScooterButton: UIButton!
    @IBOutlet weak var qrLabel: UILabel!
    
    //MARK: - Variables
    weak var delegate: HomeScooterCollectionViewCellDelegate?
    
    var scoterResult: ScooterResult?
    
    //MARK: - Life cycle

    override func awakeFromNib() {
        super.awakeFromNib()
        configureUI()
    }

    override func prepareForReuse() {
        self.scooterName.text = ""
        self.timeKMLabel.text = ""
        setImage()
        buttonContentView.backgroundColor = .white
        bokkeButtone.backgroundColor = .white
        takeScooterButton.backgroundColor = .mimoBlackWith025alpha
        self.scoterResult = nil
        super.prepareForReuse()
    }
    
    
    //MARK: - Methods

    /// configure user interface
    func configureUI() {
        viewForQR.layer.borderColor = UIColor.mimoYellow500.cgColor
        viewForQR.layer.borderWidth = 2.0
        viewForQR.layer.cornerRadius = viewForQR.frame.height / 2
        bokkeButtone.layer.borderColor = UIColor.mimoBlackWith075alpha.cgColor
        bokkeButtone.layer.borderWidth = 1
        bokkeButtone.layer.cornerRadius = Constant.CornerRadius.cornerRadius19
        takeScooterButton.layer.cornerRadius = Constant.CornerRadius.cornerRadius19
        viewForShadow.addShadow(color: .mimoBlackWith025alpha)
        contentBGView.layer.cornerRadius = 12
    }
    
    func updateUI(scoterResult: ScooterResult?, isBooked: Bool) {
        self.scoterResult = scoterResult
//        self.scoterResult?.setLocationName(long: false, in: scooterName)
        self.scooterName.text = "MAX PLUSE"//scoterResult?.type ?? ""
        let range = Double(scoterResult?.remainingMileage ?? 0) / 1000
        let timeInMinutes = range / 20 * 60 // default speed is 20km/h
        let formattedTime = secondsToHoursMinutes(Int(timeInMinutes))
        self.timeKMLabel.text = "≈\(timeInMinutes > 60 ? "\(formattedTime.0)\("SCOOTER_global_hour".localized()) \(formattedTime.1)\("SCOOTER_global_minute".localized())" : "\(formattedTime.1)\("SCOOTER_global_minute".localized())") (\(range)\("SCOOTER_global_km_range".localized()))"
        self.persentageLabel.text = "\(scoterResult?.batteryPercent ?? 0)%"
        bookNowLabel.text = isBooked ? "MOBILE_map_cancel_book".localized() : "MOBILE_map_book_now".localized()
        setImage()
        qrLabel.text = self.scoterResult?.qr ?? ""
    }
    
    private func secondsToHoursMinutes(_ minutes: Int) -> (hours: Int, minutes: Int) {
        return (minutes / 60, minutes % 60)
    }
    
    func setImage() {
        switch scoterResult?.batteryPercent ?? 0 {
        case 0...20:
            self.batareyIcon.image = UIImage(named: "ic_battery_H_0")
        case 21...40:
            self.batareyIcon.image = UIImage(named: "ic_battery_H_25")
        case 41...60:
            self.batareyIcon.image = UIImage(named: "ic_battery_H_50")
        case 61...80:
            self.batareyIcon.image = UIImage(named: "ic_battery_H_75")
        case 81...100:
            self.batareyIcon.image = UIImage(named: "ic_battery_H_100")
        default: break
        }
    }
    
    //MARK: - Methods
    
    @IBAction func bookNowButtonTapped(_ sender: UIButton) {
        delegate?.didBookNowButtonTapped(cell: self)
    }
    
    @IBAction func takeScooterButtonTapped(_ sender: UIButton) {
        delegate?.didTakeScooterButtonTapped(cell: self)
    }
    
}

