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

    var inktransform = CGAffineTransform(scaleX: 1.0, y: 1.0)
    
    // MARK: -
    // MARK: init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        var pinchGesture  = UIPinchGestureRecognizer()
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchedView))
        self.addGestureRecognizer(pinchGesture)
    }
    
    @objc func pinchedView(sender: UIPinchGestureRecognizer) {
        inktransform = CGAffineTransform(translationX: self.bounds.width/2, y: self.bounds.height/2).scaledBy(x: sender.scale, y: sender.scale).translatedBy(x: -self.bounds.width/2, y: -self.bounds.height/2)
        setNeedsDisplay()
    }
    
    
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
            
            if let predicted = event?.predictedTouches(for: touches.first!) {
                setPredictionTouches(predicted)
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
                    let sample = StrokeSample(point: getLocation(for: touch.preciseLocation(in: self)))
                    stroke.add(sample: sample)
                } else {
                    // If the touch is not the last one in the array, it was a coalesced touch.
                    let sample = StrokeSample(point: getLocation(for: touch.preciseLocation(in: self)), coalesced: true)
                    stroke.add(sample: sample)
                }
            }
            // Update the view.
            self.setNeedsDisplay()
        }
    }
    
    func setPredictionTouches(_ touches: [UITouch]) {
        if let stroke = delegate?.strokeCollection?.activeStroke {
            stroke.predictedSamples = []
            for touch in touches {
                let sample = StrokeSample(point: getLocation(for: touch.preciseLocation(in: self)))
                stroke.addPredicted(sample: sample)
            }
        }
    }
    
    func getLocation(for point: CGPoint) -> CGPoint {
        return point.applying(inktransform.inverted())
    }
    
    // MARK: -
    // MARK: rendering
    override func draw(_ rect: CGRect) {
        // Do transforms
        let context = UIGraphicsGetCurrentContext()!
        context.concatenate(inktransform)
        
        // draw all commited strokes
        if let strokes = delegate?.strokeCollection?.strokes {
            for stroke in strokes {
                stroke.color.setStroke()
                
                let path = getPath(samples: stroke.samples)
                path.lineWidth = stroke.width
                path.stroke()
            }
        }
        
        // draw active stroke opaque
        if let stroke = delegate?.strokeCollection?.activeStroke {
            // Set stroke color
            stroke.color.setStroke()
            
            // Draw commited part of stroke
            let path = getPath(samples: stroke.samples)
            path.lineWidth = stroke.width
            path.stroke()
            
            // Draw predicted path if exists
            let predictedPath = getPath(samples: stroke.predictedSamples)
            predictedPath.lineWidth = stroke.width
            //predictedPath.stroke(with: .normal, alpha: 0.7)
            predictedPath.stroke()
        }
    }
    
    func getPath(samples: [StrokeSample]) -> UIBezierPath {
        let path = UIBezierPath()
        if samples.count > 0 {
            path.move(to: samples[0].location)
            
            for i in 1..<samples.count {
                path.addLine(to: samples[i].location)
            }
        }
        
        return path
    }
}
