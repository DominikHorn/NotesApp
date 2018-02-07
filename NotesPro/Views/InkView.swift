//
//  InkView.swift
//  NotesPro
//
//  Created by Dominik Horn on 07.02.18.
//  Copyright © 2018 Dominik Horn. All rights reserved.
//

import UIKit

class InkView: UIView {
    var delegate: InkDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.newStroke(start: touches.first!.preciseLocation(in: self), sender: self)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.addPoint(point: touches.first!.preciseLocation(in: self), sender: self)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.endStroke(end: touches.first!.preciseLocation(in: self), sender: self)
    }
    
    override func draw(_ rect: CGRect) {
        if let strokes = delegate?.getStrokes(sender: self) {
            for stroke in strokes {
                stroke.color.setFill()
                stroke.color.setStroke()
                stroke.getBezierPath().stroke()
            }
        }
    }
}
