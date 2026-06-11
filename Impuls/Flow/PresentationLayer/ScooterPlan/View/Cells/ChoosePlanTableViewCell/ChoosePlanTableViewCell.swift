//
//  ChoosePlanTableViewCell.swift
//  MimoBike
//
//  Created by Karen Galoyan on 7/18/22.
//

import UIKit

protocol ChoosePlanTableViewCellDelegate: AnyObject {
    func didSelectRow(billingTariff: BillingTarif)
}

final public class ChoosePlanTableViewCell: UITableViewCell {

    // MARK: Outlets
    @IBOutlet private weak var choosePlanCollectionView: UICollectionView!
    
    // MARK: Properties
    public static let cellNibName = UINib(nibName: "ChoosePlanTableViewCell", bundle: nil)
    public static let cellIdentifier = "ChoosePlanTableViewCell"
    var singleScooterDto: SingleScooterResponse?
    var selectedSpeedTariff: SpeedTariff?
    
    weak var delegate: ChoosePlanTableViewCellDelegate?

    // MARK: Lifecycle
    public override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    // MARK: Methods
    private func setupCollectionView() {
        choosePlanCollectionView.delegate = self
        choosePlanCollectionView.dataSource = self
        choosePlanCollectionView.register(ChoosePlanCollectionViewCell.cellNibName, forCellWithReuseIdentifier: ChoosePlanCollectionViewCell.cellIdentifier)
        choosePlanCollectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .centeredHorizontally)
        DispatchQueue.main.async {
            self.choosePlanCollectionView.reloadData()
        }
    }
    
    func setData(singleScooterDto: SingleScooterResponse, speedTariff: SpeedTariff) {
        self.singleScooterDto = singleScooterDto
        self.selectedSpeedTariff = speedTariff
        setupCollectionView()
    }
}

// MARK: UICollectionViewDelegate
extension ChoosePlanTableViewCell: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("didSelectItemAt \(indexPath.item)")
        if var billingObj = singleScooterDto?.billingTariffs?[indexPath.item] {
            billingObj.isSelected = true
            delegate?.didSelectRow(billingTariff: billingObj)
            collectionView.reloadData()
        }
    }
}

// MARK: UICollectionViewDelegateFlowLayout
extension ChoosePlanTableViewCell: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = (self.frame.width / 3) - 18
        return .init(width: width, height: width)
    }
}

// MARK: UICollectionViewDataSource
extension ChoosePlanTableViewCell: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.singleScooterDto?.billingTariffs?.count ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChoosePlanCollectionViewCell.cellIdentifier, for: indexPath) as? ChoosePlanCollectionViewCell else { return UICollectionViewCell() }
        if let billingTariff = singleScooterDto?.billingTariffs?[indexPath.row] {
            
            cell.setData(billingTarif: billingTariff, price: (billingTariff.mode ?? "") == "MINUTE_BY_MINUTE" ? "\(selectedSpeedTariff?.price ?? 0.0)" : "-")
            
        }
        return cell
    }
}
