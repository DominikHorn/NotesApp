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
            
            if points.count < 2 {
                for i in 0..<points.count {
                    path.addLine(to: points[i])
                }
            } else {
                for i in 1..<(points.count-1) {
                    let p2 = points[i]
                    let p3 = points[i+1]
                
                    path.addQuadCurve(to: p3, controlPoint: p2)
                    
                    p1 = p2
                }
            }
            path.lineWidth = linewidth;
        }
        
        return path
    }
}
