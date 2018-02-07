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
    
    var currentLineWidth: CGFloat = 3.0
    var currentColor = UIColor.blue
    var inkSources = [UITouchType.stylus]

    // MARK: -
    // MARK: Touch Handling methods
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if inkSources.contains(touches.first!.type) {
            // Create a new stroke and make it the active stroke.
            let newStroke = Stroke(linewidth: currentLineWidth, color: currentColor)
            delegate?.strokeCollection?.activeStroke = newStroke
            
            // The view does not support multitouch, so get the samples
            // for only the first touch in the event.
            if let coalesced = event?.coalescedTouches(for: touches.first!) {
                addSamples(for: coalesced)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if inkSources.contains(touches.first!.type) {
            if let coalesced = event?.coalescedTouches(for: touches.first!) {
                addSamples(for: coalesced)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if inkSources.contains(touches.first!.type) {
            // Accept the current stroke and add it to the stroke collection.
            if let coalesced = event?.coalescedTouches(for: touches.first!) {
                addSamples(for: coalesced)
            }
            // Accept the active stroke.
            delegate?.strokeCollection?.acceptActiveStroke()
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if inkSources.contains(touches.first!.type) {
            // Clear the last stroke.
            delegate?.strokeCollection?.activeStroke = nil
        }
    }
    
    // MARK: -
    // MARK: helper
    func addSamples(for touches: [UITouch]) {
        if let stroke = delegate?.strokeCollection?.activeStroke {
            // Add all of the touches to the active stroke.
            for touch in touches {
                if touch == touches.last {
                    let sample = StrokeSample(point: touch.preciseLocation(in: self))
                    stroke.add(sample: sample)
                } else {
                    // If the touch is not the last one in the array,
                    //  it was a coalesced touch.
                    let sample = StrokeSample(point: touch.preciseLocation(in: self),
                                              coalesced: true)
                    stroke.add(sample: sample)
                }
            }
            // Update the view.
            self.setNeedsDisplay()
        }
    }
    
    // MARK: -
    // MARK: rendering
    override func draw(_ rect: CGRect) {
        // draw all commited strokes
        if let strokes = delegate?.strokeCollection?.strokes {
            for stroke in strokes {
                let path = getStrokePath(stroke: stroke)
                stroke.color.setStroke()
                path.stroke()
            }
        }
        
        // draw active stroke opaque
        if let stroke = delegate?.strokeCollection?.activeStroke {
            let path = getStrokePath(stroke: stroke)
            stroke.color.setStroke()
            path.stroke(with: .normal, alpha: 0.3)
        }
    }
    
    func getStrokePath(stroke: Stroke) -> UIBezierPath {
        let path = UIBezierPath()
        path.lineWidth = stroke.width
        path.move(to: stroke.samples[0].location)
        
        for i in 1..<stroke.samples.count {
            path.addLine(to: stroke.samples[i].location)
        }
        
        return path
    }
}
