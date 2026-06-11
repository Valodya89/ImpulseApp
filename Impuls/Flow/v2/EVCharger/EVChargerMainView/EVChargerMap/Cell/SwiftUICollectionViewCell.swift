//
//  SwiftUICollectionViewCell.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 7/6/25.
//

import UIKit
import SwiftUI

class SwiftUICollectionViewCell: UICollectionViewCell {
    private var hostController: UIHostingController<AnyView>?
    
    func host<Content: View>(view: Content, parent: UIViewController) {
        if let hostController = hostController {
            hostController.rootView = AnyView(view)
        } else {
            let controller = UIHostingController(rootView: AnyView(view))
            controller.view.backgroundColor = .clear
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(controller.view)
            
            NSLayoutConstraint.activate([
                controller.view.topAnchor.constraint(equalTo: contentView.topAnchor),
                controller.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                controller.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                controller.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            ])
            
            hostController = controller
            parent.addChild(controller)
            controller.didMove(toParent: parent)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        hostController?.view.removeFromSuperview()
        hostController?.removeFromParent()
        hostController = nil
    }
}
