//
//  ChargerSpecialDiscountsViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 10.07.24.
//

import UIKit

final class ChargerSpecialDiscountsViewController: UIViewController {
    
    private var tableView = UITableView()
    
    private var chargerDiscounts: [ChargerDiscount] = ChargerDiscount.staticData
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        tableView.register(ChargerDiscountsTableViewCell.self)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset.bottom = 24
        tableView.backgroundColor = .grayBackground
        tableView.separatorStyle = .none
        tableView.clipsToBounds = true
        tableView.sectionHeaderTopPadding = 0
    }
    
    private func setupConstraints() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])
    }
}

extension ChargerSpecialDiscountsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chargerDiscounts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ChargerDiscountsTableViewCell = tableView.dequeueReusableCell(for: indexPath)
        cell.set(data: chargerDiscounts[indexPath.row])
        
        return cell
    }
}

extension ChargerSpecialDiscountsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.clipsToBounds = false
        let headerTitle = UILabel()
        headerTitle.numberOfLines = 0
        headerTitle.text = "MOBILE_charger_discounts_hint".localized()
        headerTitle.font = .systemFont(ofSize: 14, weight: .light)
        
        view.addSubview(headerTitle)
        headerTitle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            headerTitle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            headerTitle.topAnchor.constraint(equalTo: view.topAnchor, constant: 20)
        ])
        view.backgroundColor = .grayBackground
        
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 90
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 122
    }
}
