//
//  PencilWidthDisplay.swift
//  NotesApp
//
//  Created by Dominik Horn on 13.03.18.
//  Copyright © 2018 Dominik Horn. All rights reserved.
//

import UIKit

class PencilWidthDisplay: UIView {
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(currentColor.cgColor)
        context.fill(CGRect(x: bounds.minX, y: bounds.height/2 - currentLineWidth/2, width: bounds.width, height: currentLineWidth))
    }
}
