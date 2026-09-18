//
//  HomeServiceCarouselCell.swift
//  Impuls
//
//  A collection view cell that hosts one SwiftUI card of the home services
//  row. The carousel itself stays UIKit (the same snapping layout as the
//  active-sessions strip); the cards are SwiftUI.
//

import UIKit
import SwiftUI

final class HomeServiceCarouselCell: UICollectionViewCell {

    static let reuseIdentifier = "HomeServiceCarouselCell"

    private var hostingController: UIHostingController<AnyView>?

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear
        // The cards draw a soft shadow past their own bounds.
        clipsToBounds = false
        contentView.clipsToBounds = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set<Content: View>(_ content: Content) {
        // A hosting view inherits the window's safe area, which would squeeze a
        // card that happens to overlap the home indicator.
        let rootView = AnyView(content.ignoresSafeArea())

        if let hostingController {
            hostingController.rootView = rootView
            return
        }

        let hostingController = UIHostingController(rootView: rootView)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        self.hostingController = hostingController
    }
}
