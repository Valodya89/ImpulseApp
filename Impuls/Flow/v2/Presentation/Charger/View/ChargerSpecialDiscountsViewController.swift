//
//  ChargerSpecialDiscountsViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 10.07.24.
//
//  The power-bank "special discounts" list, redrawn: the hint sentence on top,
//  then one card per discount (its illustration in a yellow-tinted well, a bold
//  title and a secondary description) on the ground colour.
//  `ChargerRouter.showSpecialDiscountsScreen` still wraps it in a navigation
//  controller with the title and close button.
//

import UIKit

final class ChargerSpecialDiscountsViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)

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
        view.backgroundColor = .appSecondaryBackground

        tableView.register(ChargerSpecialDiscountCardCell.self, forCellReuseIdentifier: ChargerSpecialDiscountCardCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset.bottom = 32
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.sectionHeaderTopPadding = 0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 112
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 60
        tableView.alwaysBounceVertical = true
    }

    private func setupConstraints() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension ChargerSpecialDiscountsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chargerDiscounts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChargerSpecialDiscountCardCell.reuseIdentifier, for: indexPath)
        (cell as? ChargerSpecialDiscountCardCell)?.set(data: chargerDiscounts[indexPath.row])

        return cell
    }
}

extension ChargerSpecialDiscountsViewController: UITableViewDelegate {

    /// The intro sentence: secondary text on the ground, above the cards.
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = .clear

        let hintLabel = UILabel()
        hintLabel.numberOfLines = 0
        hintLabel.text = "MOBILE_charger_discounts_hint".localized()
        hintLabel.font = UIFont(name: "Roboto-Regular", size: 14) ?? .systemFont(ofSize: 14)
        hintLabel.textColor = .appSecondaryLabel

        header.addSubview(hintLabel)
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hintLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 24),
            hintLabel.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -24),
            hintLabel.topAnchor.constraint(equalTo: header.topAnchor, constant: 16),
            hintLabel.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -12)
        ])

        return header
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
}

// MARK: - Card cell

/// One discount: illustration in a 56pt yellow-tinted well on the left, bold
/// title and secondary description on the right, on a standard card.
/// Built in code so the xib-based `ChargerDiscountsTableViewCell` the rates
/// screen still uses stays untouched.
private final class ChargerSpecialDiscountCardCell: UITableViewCell {

    static let reuseIdentifier = "ChargerSpecialDiscountCardCell"

    private static let wellSize: CGFloat = 56
    private static let cardRadius: CGFloat = 12

    private let cardView = UIView()
    private let wellView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(data: ChargerDiscount) {
        titleLabel.text = data.title
        descriptionLabel.text = data.description
        iconImageView.image = data.icon
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        cardView.layer.shadowPath = UIBezierPath(roundedRect: cardView.bounds, cornerRadius: Self.cardRadius).cgPath
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        applyAppearanceColors()
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardView.backgroundColor = .appBackground
        cardView.layer.cornerRadius = Self.cardRadius
        cardView.layer.cornerCurve = .continuous
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 8
        cardView.layer.shadowOpacity = 1

        wellView.backgroundColor = (UIColor(named: "BrandYellow") ?? .mimoYellow500).withAlphaComponent(0.14)
        wellView.layer.cornerRadius = 14
        wellView.layer.cornerCurve = .continuous

        iconImageView.contentMode = .scaleAspectFit

        titleLabel.numberOfLines = 0
        titleLabel.font = UIFont(name: "Roboto-Bold", size: 16) ?? .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .appLabel

        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = UIFont(name: "Roboto-Regular", size: 13) ?? .systemFont(ofSize: 13)
        descriptionLabel.textColor = .appSecondaryLabel

        applyAppearanceColors()
    }

    /// `CGColor`s do not follow the appearance by themselves.
    private func applyAppearanceColors() {
        cardView.layer.shadowColor = UIColor.black.withAlphaComponent(traitCollection.userInterfaceStyle == .dark ? 0.35 : 0.10).cgColor
    }

    private func setupConstraints() {
        let textStack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.alignment = .fill

        contentView.addSubview(cardView)
        cardView.addSubview(wellView)
        wellView.addSubview(iconImageView)
        cardView.addSubview(textStack)

        [cardView, wellView, iconImageView, textStack].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let textBottom = textStack.bottomAnchor.constraint(lessThanOrEqualTo: cardView.bottomAnchor, constant: -14)
        let wellBottom = wellView.bottomAnchor.constraint(lessThanOrEqualTo: cardView.bottomAnchor, constant: -14)
        let cardMinHeight = cardView.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.wellSize + 28)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            cardMinHeight,

            wellView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            wellView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            wellView.topAnchor.constraint(greaterThanOrEqualTo: cardView.topAnchor, constant: 14),
            wellBottom,
            wellView.widthAnchor.constraint(equalToConstant: Self.wellSize),
            wellView.heightAnchor.constraint(equalToConstant: Self.wellSize),

            iconImageView.topAnchor.constraint(equalTo: wellView.topAnchor, constant: 10),
            iconImageView.bottomAnchor.constraint(equalTo: wellView.bottomAnchor, constant: -10),
            iconImageView.leadingAnchor.constraint(equalTo: wellView.leadingAnchor, constant: 10),
            iconImageView.trailingAnchor.constraint(equalTo: wellView.trailingAnchor, constant: -10),

            textStack.leadingAnchor.constraint(equalTo: wellView.trailingAnchor, constant: 14),
            textStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            textStack.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            textStack.topAnchor.constraint(greaterThanOrEqualTo: cardView.topAnchor, constant: 14),
            textBottom
        ])
    }
}
