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
    
    var inkSources = [UITouchType.stylus]

    // TODO: rework
    var cachedBackground: UIImage?
    
    var inkTransform = CGAffineTransform(scaleX: 1.0, y: 1.0) {
        didSet {
            setNeedsDisplay()
        }
    }

    // MARK: -
    // MARK: init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        var pinchGesture  = UIPinchGestureRecognizer()
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchedView))
        self.addGestureRecognizer(pinchGesture)
        
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
                // Invalidate background image
                cachedBackground = nil
                
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
                    let sample = StrokeSample(point: touch.preciseLocation(in: self).applying(inkTransform.inverted()))
                    stroke.add(sample: sample)
                } else {
                    // If the touch is not the last one in the array, it was a coalesced touch.
                    let sample = StrokeSample(point: touch.preciseLocation(in: self).applying(inkTransform.inverted()), coalesced: true)
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
                let sample = StrokeSample(point: touch.preciseLocation(in: self).applying(inkTransform.inverted()))
                stroke.addPredicted(sample: sample)
            }
        }
    }

    func drawBackground(_ img: UIImage) {
        img.draw(in: bounds)
    }
    
    func drawPDF(fromUrl url: URL) -> UIImage? {
        guard let document = CGPDFDocument(url as CFURL) else { return nil }
        guard let page = document.page(at: 1) else { return nil }
        
        let pageRect = page.getBoxRect(.mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        let img = renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(pageRect)
            
            ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
            
            ctx.cgContext.drawPDFPage(page)
        }
        
        return img
    }
    
    // MARK: -
    // MARK: rendering
    override func draw(_ rect: CGRect) {
        // Do transforms
        let context = UIGraphicsGetCurrentContext()!
        context.concatenate(inkTransform)
        
        // Draw background
        if cachedBackground == nil {
            if let url = delegate?.getBackgroundPdfURL() {
                cachedBackground = drawPDF(fromUrl: url)
            }
        }
        
        if let background = cachedBackground {
            drawBackground(background)
        }
        
        // draw all commited strokes
        if let strokes = delegate?.strokeCollection?.strokes {
            for stroke in strokes {
                stroke.color.setStroke()
                
                let path = getPath(samples: stroke.samples)
                path.lineCapStyle = .round
                path.lineJoinStyle = .round
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
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.lineWidth = stroke.width
            path.stroke()
            
            // Draw predicted path if exists
            let predictedPath = getPath(samples: stroke.predictedSamples)
            predictedPath .lineCapStyle = .round
            path.lineJoinStyle = .round
            predictedPath.lineWidth = stroke.width
            predictedPath.stroke(with: .normal, alpha: 0.2)
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
