//
//  InkStroke.swift
//  NotesPro
//
//  Created by Dominik Horn on 07.02.18.
//  Copyright © 2018 Dominik Horn. All rights reserved.
//

import UIKit

class InkStroke {
    var points: [CGPoint]
    var linewidth: CGFloat
    var color: UIColor
    
    init (point: CGPoint, linewidth: CGFloat, color: UIColor) {
        self.points = [point]
        self.linewidth = linewidth
        self.color = color
    }
    
    func addPoint(newX: CGFloat, newY: CGFloat) {
        points.append(CGPoint(x: newX, y: newY))
    }
    
    func addPoint(_ p: CGPoint) {
        points.append(p)
    }
    
    func getBezierPath() -> UIBezierPath {
        let path = UIBezierPath()
        if var p1 = points.first {
            path.move(to: p1)
            
            for i in 1..<points.count {
                let p2 = points[i]
                let midPoint = getMidPoint(p1, p2)
                
                path.addQuadCurve(to: midPoint, controlPoint: getControlPoint(midPoint, p1))
                path.addQuadCurve(to: p2, controlPoint: getControlPoint(midPoint, p2))
                
                p1 = p2
            }
            path.lineWidth = linewidth;
        }
        
        return path
    }
}

func getMidPoint(_ p1: CGPoint, _ p2: CGPoint) -> CGPoint {
    return CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
}

func getControlPoint(_ p1: CGPoint, _ p2: CGPoint) -> CGPoint {
    var controlPoint = getMidPoint(p1, p2)
    let diffY = abs(p2.y - controlPoint.y)
    
    if p1.y < p2.y {
        controlPoint.y += diffY
    } else if p1.y > p2.y {
        controlPoint.y -= diffY
    }
    
    return controlPoint
}
