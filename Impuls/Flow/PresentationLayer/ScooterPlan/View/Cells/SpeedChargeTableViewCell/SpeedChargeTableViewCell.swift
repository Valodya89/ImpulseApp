//
//  SpeedChargeTableViewCell.swift
//  MimoBike
//
//  Created by Karen Galoyan on 7/17/22.
//

import UIKit

protocol SpeedChargeTableViewCellDelegate: AnyObject {
    func didSelectRow(speedTariff: SpeedTariff)
}

final public class SpeedChargeTableViewCell: UITableViewCell {

    // MARK: Outlets
    @IBOutlet private weak var speedChargeLabel: UILabel!
    @IBOutlet weak var speedChargeCollectionView: UICollectionView!
    var speedTariffs: [SpeedTariff]?
    // MARK: Properties
    public static let cellNibName = UINib(nibName: "SpeedChargeTableViewCell", bundle: nil)
    public static let cellIdentifier = "SpeedChargeTableViewCell"
    var singleScooterDto: SingleScooterResponse?
    
    weak var delegate: SpeedChargeTableViewCellDelegate?
    
    // MARK: View Lifecycle
    public override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    // MARK: Methods
    private func setupCollectionView() {
        speedTariffs = singleScooterDto?.speedTariffs?.sorted(by: {$0.speed ?? 0 < $1.speed ?? 0})
        speedChargeCollectionView.delegate = self
        speedChargeCollectionView.dataSource = self
        speedChargeCollectionView.register(SpeedChargeCollectionViewCell.cellNibName, forCellWithReuseIdentifier: SpeedChargeCollectionViewCell.cellIdentifier)
        speedChargeCollectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .centeredHorizontally)
    }
    
    func setData(singleScooterDto: SingleScooterResponse) {
        self.singleScooterDto = singleScooterDto
        setupCollectionView()
    }
}

// MARK: UICollectionViewDelegate
extension SpeedChargeTableViewCell: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("didSelectItemAt \(indexPath.item)")
        if var speedObj = speedTariffs?[indexPath.item] {
            speedObj.isSelected = true
            delegate?.didSelectRow(speedTariff: speedObj)
            DispatchQueue.main.async {
                self.speedChargeCollectionView.reloadData()
            }
        }
    }
}

// MARK: UICollectionViewDelegateFlowLayout
extension SpeedChargeTableViewCell: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (self.frame.width / 3) - 18
        return .init(width: width, height: 40)
    }
}

// MARK: UICollectionViewDataSource
extension SpeedChargeTableViewCell: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.speedTariffs?.count ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SpeedChargeCollectionViewCell.cellIdentifier, for: indexPath) as? SpeedChargeCollectionViewCell else { return UICollectionViewCell() }
        if let speedTariff = self.speedTariffs?[indexPath.item] {
            cell.setData(speedTariff: speedTariff)
        }
        return cell
    }
}
