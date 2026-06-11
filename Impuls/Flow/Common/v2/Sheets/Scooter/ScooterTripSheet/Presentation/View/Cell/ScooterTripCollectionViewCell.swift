//
//  ScooterTripCollectionViewCell.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 02.06.23.
//

import UIKit
import Combine

protocol ScooterTripCollectionViewCellDelegate: AnyObject {
    func didSelectPause(for cell: ScooterTripCollectionViewCell)
    func didSelectEndRide(for cell: ScooterTripCollectionViewCell)
    func didChangeSpeedTarif(for cell: ScooterTripCollectionViewCell, tariffTag: Int)
    func openInMaps(for cell: ScooterTripCollectionViewCell)
}

class ScooterTripCollectionViewCell: BaseCollectionViewCell {
    
    private var cancelables = Set<AnyCancellable>()

    @IBOutlet private weak var batteryImageView: UIImageView!
    @IBOutlet private weak var batteryPercentLabel: UILabel!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var travleTimeLabel: UILabel!
    @IBOutlet private weak var distanceLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var qrLabel: UILabel!
    
    @IBOutlet private var speedButtons: [SelectableButton]!
    
    weak var delegate: ScooterTripCollectionViewCellDelegate?
    private var timer: AnyCancellable?
    
    func set(data: ScooterStateModel?, pauseData: ScooterStateModel?, continueData: ScooterStateModel?, tariffs: [SpeedTariff]?) {
        batteryImageView.image = data?.scooter?.batteryPercent?.image
        batteryPercentLabel.text = (data?.scooter?.batteryPercent?.percentPrettyPrinted ?? "") + " " + (data?.scooter?.remainingMileage?.prettyPrintedWithoutRange ?? "")
        durationLabel.text = data?.scooter?.remainingMileage?.rangePrettyPrinted
        durationLabel.minimumScaleFactor = 0.1
        setTravelTime(data: data)
        qrLabel.text = data?.scooter?.qr
        
        tariffs?.enumerated().forEach({ index, value in
            let title = value.title?.replacingOccurrences(of: "km/h", with: "SCOOTER_global_km_hour".localized())
            speedButtons[index].setTitle(title, for: .normal)
            speedButtons[index].isChecked = value.id == data?.data?.speedModeTariff?.id
        })
        
        if let dist = data?.data?.distance {
            let distance: Double = abs(Double(dist / 1000))
            distanceLabel.text = "\(distance)\("MOBILE_global_km".localized())"
        }
        
        if let price = data?.data?.amount {
            let amount = Double(round(100 * price) / 100)
            priceLabel.text = "\(amount)֏"
        }
        
        if let pauseData, pauseData.data?.id == data?.data?.id {
            timer?.cancel()
            timer = nil
            
            let pausesDate = pauseData.data?.pauses?.sum
            let pauseStart = (pauseData.data?.pauses?.first(where: { $0.end == nil })?.start ?? 0) / 1000
            let start = (pauseData.data?.start ?? 0)/1000
            let totalSeconds = Double(pauseStart) - start - Double(pausesDate ?? 0)/1000
            self.travleTimeLabel.text = DateComponentsFormatter.hmsFormatter.string(from: TimeInterval(totalSeconds))
        } else if let continueData, continueData.data?.id == data?.data?.id {
            updateTravleTimer(with: continueData)
        } else if let data {
            updateTravleTimer(with: data)
        }
    }
    
    private func updateTravleTimer(with data: ScooterStateModel) {
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
            .sink(receiveValue: { [weak self] _ in
                self?.setTravelTime(data: data)
            })
    }
    
    private func setTravelTime(data: ScooterStateModel?) {
        guard let data else { return }
        
        let pausesDate = data.data?.pauses?.filter({ $0.end != nil }).compactMap({ ($0.end ?? 0) - ($0.start ?? 0) }).reduce(0, +)
        let start = (data.data?.start ?? 0)/1000
        let pauses = Double(pausesDate ?? 0)/1000
        
        let total = Date().timeIntervalSince1970 - start - pauses
        self.travleTimeLabel.text = DateComponentsFormatter.hmsFormatter.string(from: TimeInterval(total))
    }
    
    @IBAction private func speedActon(_ sender: SelectableButton) {
        speedButtons.forEach({ $0.isChecked = sender.tag == $0.tag })
        delegate?.didChangeSpeedTarif(for: self, tariffTag: sender.tag)
    }
    
    @IBAction private func pauseAction() {
        delegate?.didSelectPause(for: self)
    }
    
    @IBAction private func endRideAction() {
        delegate?.didSelectEndRide(for: self)
    }
    
    @IBAction private func openInMapsAction() {
        delegate?.openInMaps(for: self)
    }
}
