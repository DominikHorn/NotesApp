//
//  InkView.swift
//  NotesPro
//
//  Created by Dominik Horn on 07.02.18.
//  Copyright © 2018 Dominik Horn. All rights reserved.
//

import UIKit


class InkView: UIView {
    var strokes: [[CGPoint]] = []
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        strokes.append([touches.first!.preciseLocation(in: self)])
        self.setNeedsDisplay()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        strokes[strokes.count-1].append(touches.first!.preciseLocation(in: self))
        self.setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        strokes[strokes.count-1].append(touches.first!.preciseLocation(in: self))
        self.setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        for points in strokes {
            let path = UIBezierPath()
            if let fp = points.first {
                path.move(to: fp)
                for p in points {
                    path.addLine(to: p)
                }
                UIColor.darkGray.setFill()
                UIColor.darkGray.setStroke()
                path.lineWidth = 3.0;
                path.stroke()
            }
        }
    }
}
