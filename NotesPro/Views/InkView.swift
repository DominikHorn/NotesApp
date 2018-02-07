//
//  InkView.swift
//  NotesPro
//
//  Created by Dominik Horn on 07.02.18.
//  Copyright © 2018 Dominik Horn. All rights reserved.
//

import UIKit


class InkView: UIView {
    var strokes: [InkStroke] = []
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        strokes.append(InkStroke(touches.first!.preciseLocation(in: self)))
        self.setNeedsDisplay()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        strokes[strokes.count-1].addPoint((touches.first!.preciseLocation(in: self)))
        self.setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        strokes[strokes.count-1].addPoint((touches.first!.preciseLocation(in: self)))
        self.setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        for stroke in strokes {
            stroke.getBezierPath().stroke()
        }
    }
}
