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
        if let fp = points.first {
            path.move(to: fp)
            for p in points {
                path.addLine(to: p)
            }
            path.lineWidth = linewidth;
        }
        
        return path
    }
}
