//
//  ZoneInfoViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 19.07.23.
//

import UIKit
import Combine

class ZoneInfoViewController: UIViewController {
    
    private var cancelables = Set<AnyCancellable>()
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    var viewModel: ZoneInfoViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        
        viewModel?.$zoneInfo.sink(receiveValue: { [weak self] zoneInfo in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self?.tableView.reloadData()
            }
        })
        .store(in: &cancelables)
        
        viewModel?.getZoneInfo()
        tableViewHeightConstraint.constant = viewModel?.zoneType == nil ? 300 : 80
        DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
            self.tableView.reloadData()
        }
    }
    
    private func setupUI() {
        tableView.register(ZoneInfoTableViewCell.self)
    }
    
    @IBAction private func doneAction() {
        (self.parent?.parent as? SheetViewController)?.attemptDismiss(animated: true)
    }
}

extension ZoneInfoViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.zoneInfo?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ZoneInfoTableViewCell = tableView.dequeueReusableCell(for: indexPath)
        if let zoneInfo = viewModel?.zoneInfo?[indexPath.row] {
            cell.set(zoneInfo: zoneInfo)
        }
        
        return cell
    }
}

extension ZoneInfoViewController: UITableViewDelegate { }
