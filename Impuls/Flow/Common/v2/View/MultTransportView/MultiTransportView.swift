//
//  MultiTransportView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 17.06.23.
//

import UIKit

protocol MultiTransportViewDelegate: AnyObject {
    func didSelectItem(with index: Int)
    func didSelectNewItem()
}

class MultiTransportView: UIView {
    
    @IBOutlet private var contentView: UIView!
    @IBOutlet private var collectionView: UICollectionView!
    
    private var rows: [Row] = []
    
    var data: [String] = [] {
        didSet {
            setupDataSource()
        }
    }
    
    var selected: String? {
        didSet {
            collectionView.reloadData()
        }
    }
    
    var selectedIndex: Int = 0 {
        didSet {
            collectionView.scrollToItem(at: IndexPath(row: selectedIndex, section: 0), at: .centeredHorizontally, animated: true)
        }
    }
    
    var service: MimoType = .scooter
    var maxCount: Int = 3
    weak var delegate: MultiTransportViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("MultiTransportView", owner: self)
        addSubview(contentView)
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        collectionView.register(MultiTransportOneMoreCollectionViewCell.self)
        collectionView.register(MultiTransportViewCollectionViewCell.self)
        collectionView.register(MultiTransportPlusCollectionViewCell.self)
        
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    }
    
    private func setupDataSource() {
        rows = []
        if data.count == 1 {
            rows = [.oneMore]
        } else if data.count > 1 && data.count < maxCount {
            rows = Array(repeating: .item, count: data.count)
            rows.append(.plus)
        } else if data.count == maxCount {
            rows = Array(repeating: .item, count: data.count)
        }
        
        collectionView.reloadData()
    }
}

extension MultiTransportView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return rows.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch rows[indexPath.item] {
        case .oneMore:
            let cell: MultiTransportOneMoreCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
            
            return cell
        case .item:
            let cell: MultiTransportViewCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
            cell.title = data[indexPath.item]
            cell.isChecked = data[indexPath.item] == selected
            
            return cell
        case .plus:
            let cell: MultiTransportPlusCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
            
            return cell
        }
    }
}

extension MultiTransportView: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch rows[indexPath.item] {
        case .oneMore, .plus:
            delegate?.didSelectNewItem()
        case .item:
            delegate?.didSelectItem(with: indexPath.item)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch rows[indexPath.item] {
        case .oneMore:
            return CGSize(width: 116, height: collectionView.frame.height)
        case .item:
            return CGSize(width: service == .scooter ? 84 : 134, height: collectionView.frame.height)
        case .plus:
            return CGSize(width: 44, height: collectionView.frame.height)
        }
    }
}

extension MultiTransportView {
    
    enum Row: Int {
        case oneMore
        case item
        case plus
    }
}
