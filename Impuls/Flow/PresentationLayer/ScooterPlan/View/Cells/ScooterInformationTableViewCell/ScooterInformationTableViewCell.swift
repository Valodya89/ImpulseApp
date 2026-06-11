//
//  ScooterInformationTableViewCell.swift
//  MimoBike
//
//  Created by Karen Galoyan on 7/17/22.
//

import UIKit
import GoogleMaps
import CoreLocation

final public class ScooterInformationTableViewCell: UITableViewCell {

    // MARK: Outlets
    @IBOutlet private weak var viewForQR: UIView!
    @IBOutlet private weak var qrLabel: UILabel!
    @IBOutlet private weak var scooterNameLabel: UILabel!
    @IBOutlet private weak var batteryImageView: UIImageView!
    @IBOutlet private weak var batteryPercentageLabel: UILabel!
    @IBOutlet private weak var locationAddressLabel: UILabel!
    @IBOutlet private weak var tripRangeLabel: UILabel!
    
    // MARK: Properties
    public static let cellNibName = UINib(nibName: "ScooterInformationTableViewCell", bundle: nil)
    public static let cellIdentifier = "ScooterInformationTableViewCell"
    let geocoder = GMSGeocoder()
    
    // MARK: View Lifecycle
    public override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    // MARK: Methods
    func setData(singleScooterDto: SingleScooterResponse) {
        scooterNameLabel.text = "MAX PLUSE"
        setImage(scooterResult: singleScooterDto)
        batteryPercentageLabel.text = "\(singleScooterDto.scooter?.batteryPercent ?? 0)%"
        self.getLocationName(lat: singleScooterDto.scooter?.located?.latitude ?? 0.0, lng: singleScooterDto.scooter?.located?.longitude ?? 0.0, long: true) { value in
            self.locationAddressLabel.text = value
        }
        
        let range = Double(singleScooterDto.scooter?.remainingMileage ?? 0) / 1000
        let timeInMinutes = range / 20 * 60 // default speed is 20km/h
        let formattedTime = secondsToHoursMinutes(Int(timeInMinutes))
        self.tripRangeLabel.text = "≈\(timeInMinutes > 60 ? "\(formattedTime.0)\("SCOOTER_global_hour".localized()) \(formattedTime.1)\("SCOOTER_global_minute".localized())" : "\(formattedTime.1)\("SCOOTER_global_minute".localized())")\n (\(range)\("SCOOTER_global_km_range".localized()))"
        viewForQR.layer.borderColor = UIColor.mimoYellow500.cgColor
        viewForQR.layer.borderWidth = 2.0
        viewForQR.layer.cornerRadius = viewForQR.frame.height / 2
        qrLabel.text = singleScooterDto.scooter?.qr
    }
    
    func setImage(scooterResult: SingleScooterResponse ) {
        if let scooter = scooterResult.scooter {
            switch scooterResult.scooter?.batteryPercent ?? 0 {
            case 0...20:
                self.batteryImageView.image = UIImage(named: "ic_battery_H_0")
            case 21...40:
                self.batteryImageView.image = UIImage(named: "ic_battery_H_25")
            case 41...60:
                self.batteryImageView.image = UIImage(named: "ic_battery_H_50")
            case 61...80:
                self.batteryImageView.image = UIImage(named: "ic_battery_H_75")
            case 81...100:
                self.batteryImageView.image = UIImage(named: "ic_battery_H_100")
            default: break
            }
        }
        
    }
    
    private func secondsToHoursMinutes(_ minutes: Int) -> (hours: Int, minutes: Int) {
        return (minutes / 60, minutes % 60)
    }
    
    func getLocationName(lat: Double, lng: Double, long: Bool, completed: @escaping (String) -> ()) {
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        
        geocoder.reverseGeocodeCoordinate(coordinate) { (result, error) in
            
            guard let response = result?.firstResult() else { return }
            
            let lines = response.lines?.first ?? "---"
            let thoroughfare = response.thoroughfare ?? "---"
            completed((long) ? lines : thoroughfare)
        }
    }
}
