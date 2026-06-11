//
//  View+Extensions.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 3/1/25.
//

import SwiftUI

extension View {
    func snapshot() -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view
        
        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

extension View {
    func roundedBorderMedium(color: Color = .gray4, lineWidth: CGFloat = 0.5) -> some View {
        self
            .modifier(RoundedBorder(radius: 8, color: color, lineWidth: lineWidth))
    }
}

extension View {
    func sectionTopContent(icon: String? = nil, label: String, labelValue: String? = nil) -> some View {
        self
            .modifier(SectionTopViewModifier(icon: icon, label: label, labelValue: labelValue))
    }
}
