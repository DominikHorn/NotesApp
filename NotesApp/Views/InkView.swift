//
//  InkView.swift
//  NotesPro
//
//  Created by Dominik Horn on 07.02.18.
//  Copyright © 2018 Dominik Horn. All rights reserved.
//

import UIKit

class InkView: UIView {
    var delegate: InkDelegate? {
        didSet {
            if let pdf = self.delegate?.getBackgroundPdfURL() {
                let page = CGPDFDocument(pdf as CFURL)?.page(at: 1)
                if let pageRect = page?.getBoxRect(.mediaBox) {
                    cachedBackground = FastPDFView(bounds: CGRect(x: bounds.width/2 - pageRect.width, y: bounds.height/2 - pageRect.height, width: pageRect.width*2, height: pageRect.height*2))
                    cachedBackground?.refresh(withPDF: pdf)
                }
            }
        }
    }
    var inkSources = [UITouchType.stylus]
    
    var cachedBackground: FastPDFView?
    
    var inkTransform = CGAffineTransform(scaleX: 1.0, y: 1.0) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var straightLineTimer: Timer?
    
    // MARK: -
    // MARK: init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(pinchedView)))
        self.layer.drawsAsynchronously = true
        
        self.isMultipleTouchEnabled = true
    }
    
    var prevloc = CGPoint(x: 0, y: 0)
    @objc func pinchedView(recog: UIPinchGestureRecognizer) {
        if recog.state == .began {
            prevloc = recog.location(in: self)
        }
        
        if recog.state == .changed {
            if recog.numberOfTouches == 2 {
                let zc = recog.location(in: self).applying(inkTransform.inverted())
                inkTransform = inkTransform.translatedBy(x: zc.x, y: zc.y).scaledBy(x: recog.scale, y: recog.scale).translatedBy(x: -zc.x, y: -zc.y)
                recog.scale = 1
                
                var transl = recog.location(in: self)
                transl.x -= prevloc.x
                transl.y -= prevloc.y
                inkTransform = inkTransform.concatenating(CGAffineTransform(translationX: transl.x, y: transl.y))
                prevloc = recog.location(in: self)
            } else {
                recog.isEnabled = false
                recog.isEnabled = true
            }
        }
        
        if recog.state == .ended || recog.state == .cancelled || recog.state == .failed {
            // Invalidate background image
            if let url = delegate?.getBackgroundPdfURL() {
                cachedBackground?.refresh(withPDF: url, scaleFac: inkTransform.a)
                setNeedsDisplay()
            }
        }
    }
    
    func restartStraightLineTimer() {
        straightLineTimer?.invalidate()
        straightLineTimer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: false) { [unowned self] t in
            if let samples = self.delegate?.strokeCollection?.activeStroke?.samples {
                if let firstSample = samples.first {
                    self.delegate?.strokeCollection?.activeStroke?.samples = [firstSample, samples[samples.count - 1]]
                    self.delegate?.strokeCollection?.activeStroke?.predictedSamples = []
                    self.delegate?.strokeCollection?.activeStroke?.isStraight = true
                    self.setNeedsDisplay()
                }
            }
        }
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
            
            restartStraightLineTimer()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if inkSources.contains(touches.first!.type) {
            if let prevloc = touches.first?.precisePreviousLocation(in: self) {
                if let loc = touches.first?.preciseLocation(in: self) {
                    if (loc.x - prevloc.x)*(loc.x - prevloc.x) + (loc.y - prevloc.y)*(loc.y - prevloc.y) > 1 {
                        restartStraightLineTimer()
                    }
                }
            }
            
            if let coalesced = event?.coalescedTouches(for: touches.first!) {
                addSamples(for: coalesced)
            }
            
            if let predicted = event?.predictedTouches(for: touches.first!) {
                setPredictionTouches(predicted)
            }
        } else {
            var transl = CGPoint(x: 0, y: 0)
            if touches.count == 2 {
                for touch in touches {
                    let touchloc = touch.location(in: self)
                    let prevloc = touch.previousLocation(in: self)
                    transl.x += touchloc.x - prevloc.x
                    transl.y += touchloc.y - prevloc.y
                }
                transl.x /= CGFloat(touches.count)
                transl.y /= CGFloat(touches.count)
            } else {
                let l = touches.first!.location(in: self)
                let pl = touches.first!.previousLocation(in: self)
                transl.x = l.x - pl.x
                transl.y = l.y - pl.y
            }
            
            inkTransform = inkTransform.concatenating(CGAffineTransform(translationX: transl.x, y: transl.y))
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if inkSources.contains(touches.first!.type) {
            straightLineTimer?.invalidate()
            
            // Accept the current stroke and add it to the stroke collection.
            if let coalesced = event?.coalescedTouches(for: touches.first!) {
                addSamples(for: coalesced)
            }
            // Accept the active stroke.
            delegate?.acceptActiveStroke()
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if inkSources.contains(touches.first!.type) {
            straightLineTimer?.invalidate()
            
            // Clear the last stroke.
            if delegate?.strokeCollection?.activeStroke?.isStraight == false {
                delegate?.strokeCollection?.activeStroke = nil
                setNeedsDisplay()
            } else {
                delegate?.acceptActiveStroke()
            }
        }
    }
    
    // MARK: -
    // MARK: helper
    func addSamples(for touches: [UITouch]) {
        if let stroke = delegate?.strokeCollection?.activeStroke {
            if stroke.isStraight {
                if let last = touches.last {
                    stroke.samples[stroke.samples.count - 1] = StrokeSample(point: last.preciseLocation(in: self).applying(inkTransform.inverted()))
                }
            } else {
                // Add all of the touches to the active stroke.
                for touch in touches {
                    if touch == touches.last {
                        let sample = StrokeSample(point: touch.preciseLocation(in: self).applying(inkTransform.inverted()))
                        stroke.add(sample: sample)
                    } else {
                        // If the touch is not the last one in the array, it was a coalesced touch.
                        let sample = StrokeSample(point: touch.preciseLocation(in: self).applying(inkTransform.inverted()), coalesced: true)
                        stroke.add(sample: sample)
                    }
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
                let sample = StrokeSample(point: touch.preciseLocation(in: self).applying(inkTransform.inverted()))
                stroke.addPredicted(sample: sample)
            }
        }
    }
    
    // MARK: -
    // MARK: rendering
    override func draw(_ rect: CGRect) {
        // Do transforms
        let context = UIGraphicsGetCurrentContext()!
        context.concatenate(inkTransform)
        context.interpolationQuality = .high
        
        // Draw background if we have any
        if let background = cachedBackground {
            context.saveGState()
            context.setShadow(offset: CGSize(width: 0, height: 5), blur: 10)
            background.draw()
            context.restoreGState()
        }
        
        // draw all commited strokes
        if let strokes = delegate?.strokeCollection?.strokes {
            for stroke in strokes {
                stroke.color.setStroke()
                
                // calc path if not existant
                if stroke.path == nil{
                    stroke.path = getPath(samples: stroke.samples)
                }
                
                // draw path
                if let path = stroke.path {
                    path.lineCapStyle = .round
                    path.lineJoinStyle = .round
                    path.lineWidth = stroke.width
                    path.stroke()
                }
            }
        }
        
        // draw active stroke
        if let stroke = delegate?.strokeCollection?.activeStroke {
            // Set stroke color
            stroke.color.setStroke()
            
            // Draw commited part of stroke
            let path = getPath(samples: stroke.samples)
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.lineWidth = stroke.width
            path.stroke()
            
            // Draw predicted path if exists
            if !stroke.isStraight {
                let predictedPath = getPath(samples: stroke.predictedSamples)
                predictedPath .lineCapStyle = .round
                path.lineJoinStyle = .round
                predictedPath.lineWidth = stroke.width
                predictedPath.stroke(with: .normal, alpha: 0.2)
            }
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

