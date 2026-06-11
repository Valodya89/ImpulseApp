//
//  PackageTableView.swift
//  MimoBike
//
//  Created by Dose on 6/5/21.
//

import UIKit

protocol PlanTableViewDelegate: AnyObject {
    func numberOfItems(in tableView: UITableView) -> Int
    func cell(for index: Int, table tableView: UITableView) -> UITableViewCell
    func height(for index: Int) -> CGFloat
}

extension PlanTableViewDelegate {
    func height(for index: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
}

final class PlanTableView: UIView {
    
    @IBOutlet weak var tableView: SizedTableView!
    
    weak var delegate: PlanTableViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        loadFromNib()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        
    }
    
    func register(cells: UITableViewCell...) {
        cells.forEach { cell in
            tableView.register(type(of: cell).self, forCellReuseIdentifier: String(describing: type(of: cell)))
        }
    }
    
    func register(cells: (nib: UINib, cell: UITableViewCell.Type)...) {
        cells.forEach { cell in
            tableView.register(cell.nib, forCellReuseIdentifier: String(describing: cell.cell))
        }
    }
    
    func reloadData() {
        tableView.reloadData()
        tableView.invalidateIntrinsicContentSize()
    }
}

extension PlanTableView: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return delegate?.numberOfItems(in: tableView) ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = delegate?.cell(for: indexPath.row, table: tableView) else {
            assertionFailure("Delegate is empty something went wrong.")
            return UITableViewCell()
        }
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return delegate?.height(for: indexPath.row) ?? UITableView.automaticDimension
    }
}
