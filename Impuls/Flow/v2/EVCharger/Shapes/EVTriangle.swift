//
//  EVTriangle.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 07.02.25.
//

import SwiftUI

struct EVTriangle: Shape {
    let radius: CGFloat
    let angleShape: TriangleShape
    
    func path(in rect: CGRect) -> Path {
        switch angleShape {
        case .rightTrianglelTopTrailing:
            
            return Path({ path in
                let p1 = CGPoint(x: rect.minX, y: rect.minY)
                let p2 = CGPoint(x: rect.maxX, y: rect.minY)
                let p3 = CGPoint(x: rect.maxX, y: rect.maxY)
                path.move(to: p3)
                path.addArc(tangent1End: p1, tangent2End: p2, radius: 0)
                path.addArc(tangent1End: p2, tangent2End: p3, radius: radius)
                path.addArc(tangent1End: p3, tangent2End: p1, radius: 0)
            })
            
        case .isoscelesTriangleTrailing:
            
            return Path({ path in
                let p1 = CGPoint(x: rect.minX, y: rect.minY)
                let p2 = CGPoint(x: rect.maxX, y: rect.midY)
                let p3 = CGPoint(x: rect.minX, y: rect.maxY)
                path.move(to: p3)
                path.addArc(tangent1End: p1, tangent2End: p2, radius: radius)
                path.addArc(tangent1End: p2, tangent2End: p3, radius: radius)
                path.addArc(tangent1End: p3, tangent2End: p1, radius: radius)
            })
        }
    }
}

extension EVTriangle {
    enum TriangleShape {
        case rightTrianglelTopTrailing
        case isoscelesTriangleTrailing
    }
}

#Preview {
    EVTriangle(radius: 10, angleShape: .isoscelesTriangleTrailing)
}
