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
    
    init(_ p: CGPoint) {
        points = [p]
        linewidth = 2
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
            UIColor.darkGray.setFill()
            UIColor.darkGray.setStroke()
            path.lineWidth = 3.0;
        }
        
        return path
    }
}
