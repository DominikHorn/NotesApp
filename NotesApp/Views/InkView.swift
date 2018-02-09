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
            guard let pdf = delegate?.getBackgroundPdfURL() else { return }
            guard let page = CGPDFDocument(pdf as CFURL)?.page(at: 1) else { return }
            
            let pageRect = page.getBoxRect(.mediaBox)
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: pageRect.width, height: pageRect.height))
            self.cachedBackground = renderer.image { ctx in
                // Draw background pdf
                UIColor.white.setFill()
                ctx.cgContext.interpolationQuality = .high
                //ctx.cgContext.scaleBy(x: scaleFac, y: -scaleFac)
                //ctx.cgContext.translateBy(x: 0, y: -pageRect.height)
                ctx.cgContext.fill(pageRect)
                ctx.cgContext.saveGState()
                ctx.cgContext.setShadow(offset: CGSize(width: 0, height: 5), blur: 10)
                ctx.cgContext.drawPDFPage(page)
                ctx.cgContext.restoreGState()
            }
        }
    }
    var inkSources = [UITouchType.stylus]
    
    var cachedBackground: UIImage?
    var highQualityBackground: UIImage?
    
    private var inkTransform = CGAffineTransform(scaleX: 1.0, y: 1.0)
    
    // MARK: -
    // MARK: init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // Setup view
        self.layer.drawsAsynchronously = true
        self.isMultipleTouchEnabled = true
        
        self.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(pinchedView)))
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
                
                highQualityBackground = nil
                setNeedsDisplay()
            } else {
                recog.isEnabled = false
                recog.isEnabled = true
            }
        }
        
        if recog.state == .ended || recog.state == .cancelled || recog.state == .failed {
            updateBackground()
            setNeedsDisplay()
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
            highQualityBackground = nil
            setNeedsDisplay()
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
        updateBackground()
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
            
            setNeedsDisplay()
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
    func updateBackground() {
        if highQualityBackground == nil {
            print("\(Date()) Refreshing background")
            
            // Render high quality section of pdf background
            // TODO: only do this when necessary (zoom > 1)
            guard let pdf = delegate?.getBackgroundPdfURL() else { return }
            guard let page = CGPDFDocument(pdf as CFURL)?.page(at: 1) else { return }
            let pageRect = page.getBoxRect(.mediaBox)
            
            let renderSize = bounds.size
            let renderer = UIGraphicsImageRenderer(size: renderSize)
            DispatchQueue.global(qos: .userInteractive).async { [unowned self] in
                self.highQualityBackground = renderer.image { [unowned self] ctx in
                    // Draw background pdf
                    UIColor.white.setFill()
                    ctx.cgContext.scaleBy(x: 1, y: -1)
                    ctx.cgContext.translateBy(x: 0, y: -renderSize.height)
                    ctx.cgContext.concatenate(self.inkTransform)
                    ctx.cgContext.fill(pageRect)
                    ctx.cgContext.drawPDFPage(page)
                }
                
                DispatchQueue.main.async {
                    self.setNeedsDisplay()
                }
            }
        }
    }
    
    override func draw(_ rect: CGRect) {
        // Do transforms
        guard let background = cachedBackground else { return }
        guard let pdf = delegate?.getBackgroundPdfURL() else { return }
        guard let page = CGPDFDocument(pdf as CFURL)?.page(at: 1) else { return }
        let pageRect = page.getBoxRect(.mediaBox)
        let context = UIGraphicsGetCurrentContext()!
        
        context.interpolationQuality = .high
        context.saveGState()
        context.saveGState()
        context.concatenate(inkTransform)
        context.setShadow(offset: CGSize(width: 0, height: 5), blur: 10)
        context.draw(background.cgImage!, in: pageRect)
        context.restoreGState()
        if let hqBackground = highQualityBackground {
            context.draw(hqBackground.cgImage!, in: bounds)
        }
        context.concatenate(inkTransform)
        
        // draw inking
        if let strokes = self.delegate?.strokeCollection?.strokes {
            for stroke in strokes {
                if let path = stroke.path {
                    stroke.color.setStroke()
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
            
            // Draw known part of stroke
            if let path = stroke.path {
                path.lineCapStyle = .round
                path.lineJoinStyle = .round
                path.lineWidth = stroke.width
                path.stroke()
            }
            
            // Draw predicted path if exists
            if let predictedPath = stroke.predictedPath {
                predictedPath.lineCapStyle = .round
                predictedPath.lineJoinStyle = .round
                predictedPath.lineWidth = stroke.width
                predictedPath.stroke(with: .normal, alpha: 0.2)
            }
        }
        context.restoreGState()
    }
}
