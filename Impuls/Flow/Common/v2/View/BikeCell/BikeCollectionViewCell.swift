//
//  BikeCollectionViewCell.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 21.07.23.
//

import UIKit
import Combine
import CoreLocation

protocol BikeCollectionViewCellDelegate: AnyObject {
    func bookAction(for cell: BikeCollectionViewCell)
    func takeAction(for cell: BikeCollectionViewCell)
}

class BikeCollectionViewCell: BaseCollectionViewCell {
    
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var timeLabel: UILabel!
    
    weak var delegate: BikeCollectionViewCellDelegate?
    
    private var addressPublisher: AnyPublisher<String, Never> {
        return addressSubject.eraseToAnyPublisher()
    }
    
    private let addressSubject = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()

    override func awakeFromNib() {
        super.awakeFromNib()
        
        addShadow(color: .black.withAlphaComponent(0.4), offset: .init(width: 0, height: 4), shadowRadius: 12)
    }
    
    func set(bike: BikeResult) {
        timeLabel.text = bike.timePrettyPrinted
        
        addressPublisher.receive(on: DispatchQueue.main)
            .sink { address in
                self.addressLabel.text = address
            }
            .store(in: &cancellables)
        
        Task {
            await getAddress(from: bike.coordinate)
        }
    }
    
    @IBAction private func bookAction() {
        delegate?.bookAction(for: self)
    }
    
    @IBAction private func takeAction() {
        delegate?.takeAction(for: self)
    }

    private func getAddress(from coordinate: CLLocationCoordinate2D) async {
        let addressHelper: AddressHelperProtocol = Resolver.resolve()
        guard let address = try? await addressHelper.getAddress(for: coordinate, fullAddress: false) else { return }
        
        addressSubject.send(address)
    }
}
