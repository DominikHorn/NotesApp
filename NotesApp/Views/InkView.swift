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
            redrawBackground()
            
            // Center page initially
            guard let pdf = delegate?.getBackgroundPdfURL() else { return }
            guard let page = CGPDFDocument(pdf as CFURL)?.page(at: 1) else { return }
            
            let pageRect = page.getBoxRect(.mediaBox)
            inkTransform = CGAffineTransform(translationX: self.bounds.width/2 - pageRect.width/2, y: 0)
        }
    }
    
    var inkSources = [UITouchType.stylus]
    
    var cachedBackground: UIImage?
    var highQualityBackground: UIImage?

    private var inkTransform = CGAffineTransform(scaleX: 1.0, y: 1.0)
    var straightLineTimer: Timer?

    // MARK: -
    // MARK: init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        // Setup view
        self.layer.drawsAsynchronously = true
        self.isMultipleTouchEnabled = true

        self.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(pinchedView)))
    }

    // Previous position of pinch
    private var prevloc = CGPoint(x: 0, y: 0)
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

                // This will also redraw the normal background
                self.invalidateHighQualityBackground()
                setNeedsDisplay()
            } else {
                recog.isEnabled = false
                recog.isEnabled = true
            }
        }

        if recog.state == .ended || recog.state == .cancelled || recog.state == .failed {
            redrawHighQualityBackground()
        }
    }

    func restartStraightLineTimer() {
        straightLineTimer?.invalidate()
        straightLineTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [unowned self] t in
            if let samples = self.delegate?.strokeCollection?.activeStroke?.samples {
                if let firstSample = samples.first {
                    self.delegate?.strokeCollection?.activeStroke?.set(samples: [firstSample, samples[samples.count - 1]])
                    self.delegate?.strokeCollection?.activeStroke?.isStraight = true
                    self.setNeedsDisplay()
                }
            }
        }
    }

    // MARK: -
    // MARK: View Event Handeling
    override func layoutSubviews() {
        fullRedraw()
    }
    
    // MARK: -
    // MARK: Touch Handling methods
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if inkSources.contains(touches.first!.type) {
            // Create a new stroke and make it the active stroke.
            let newStroke = Stroke(linewidth: currentLineWidth, color: currentColor)
            delegate?.strokeCollection?.activeStroke = newStroke


            addSamples(for: [touches.first!])
            if let coalesced = event?.coalescedTouches(for: touches.first!) {
                addSamples(for: coalesced)
            }

            restartStraightLineTimer()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // TODO: calc translation
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
        
        // TODO: rework with translation
        if inkSources.contains(touches.first!.type) {
            if let prevloc = touches.first?.precisePreviousLocation(in: self) {
                if let loc = touches.first?.preciseLocation(in: self) {
                    if (loc.x - prevloc.x)*(loc.x - prevloc.x) + (loc.y - prevloc.y)*(loc.y - prevloc.y) > 0.1 {
                        restartStraightLineTimer()
                    }
                }
            }

            if let coalesced = event?.coalescedTouches(for: touches.first!) {
                addSamples(for: coalesced)
            }
        } else if delegate?.strokeCollection?.activeStroke == nil {
            inkTransform = inkTransform.concatenating(CGAffineTransform(translationX: transl.x, y: transl.y))
            self.invalidateHighQualityBackground()
            setNeedsDisplay()
        } else {
            if let stro = delegate?.strokeCollection?.activeStroke {
                if stro.isStraight {
                    let dampfac: CGFloat = 0.2
                
                    for i in 0..<stro.samples.count {
                        stro.samples[i] = StrokeSample(point: CGPoint(x: stro.samples[i].location.x + transl.x * dampfac, y: stro.samples[i].location.y + transl.y * dampfac))
                    }
                }
            }
            
            if highQualityBackground == nil {
                redrawHighQualityBackground()
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if inkSources.contains(touches.first!.type) {
            straightLineTimer?.invalidate()

            // Accept the active stroke.
            delegate?.acceptActiveStroke()
            redrawBackground()
            redrawHighQualityBackground()
        } else {
            if highQualityBackground == nil {
                redrawHighQualityBackground()
            }
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
        } else {
            if highQualityBackground == nil {
                redrawHighQualityBackground()
            }
        }
    }

    // MARK: -
    // MARK: helper
    func getAngleFrom(start: CGPoint, end: CGPoint) -> CGFloat {
        // TODO: remove intermediate radian to degree conversion
        return atan2(start.x - end.x, start.y - end.y)
    }
    
    func lengthOf(start: CGPoint, end: CGPoint) -> CGFloat {
        let vec = CGPoint(x: start.x - end.x, y: start.y - end.y)
        return sqrt(vec.x * vec.x + vec.y * vec.y)
    }
    
    func round(number: CGFloat, toNearestMultipleOf m: CGFloat) -> CGFloat {
        // TODO: remove intermediate radian to degree conversion
        var negativeResult = false
        var tmp = number / m
        if tmp < 0 {
            tmp = -tmp
            negativeResult = true
        }
        var rndTmp: Int = 0
        if tmp - CGFloat(Int(tmp)) >= 0.5 {
            rndTmp = Int(tmp) + 1
        } else {
            rndTmp = Int(tmp)
        }
        if negativeResult {
                rndTmp = -rndTmp
        }
        
        let result = m * CGFloat(rndTmp)
        return result
    }
    
    func addSamples(for touches: [UITouch]) {
        if let stroke = delegate?.strokeCollection?.activeStroke {
            if stroke.isStraight {
                if let last = touches.last {
                    let startStroke = stroke.samples.first!
                    var endStroke = StrokeSample(point: last.preciseLocation(in: self).applying(inkTransform.inverted()))
                    let angle = getAngleFrom(start: startStroke.location, end: endStroke.location)
        
                    // TODO: remove intermediate radian to degree conversion
                    // TODO: refactor into shape toolbar
                    var remainder = angle.truncatingRemainder(dividingBy: snappingStep)
                    if remainder < 0 {
                        remainder = -remainder
                    }
                    
                    if shouldSnap && (remainder < snappingInterval || snappingStep - remainder < snappingInterval) {
                        let snappedAngle = round(number: angle, toNearestMultipleOf: snappingStep) + CGFloat.pi / 2.0
                        let length = lengthOf(start: startStroke.location, end: endStroke.location)
                        
                        var dx = cos(snappedAngle) * length
                        var dy = -sin(snappedAngle) * length
                        
                        // Fix rounding error
                        if dx * dx < 0.0001 {
                            dx = 0
                        }
                        if dy * dy < 0.0001 {
                            dy = 0
                        }
                        
                        endStroke = StrokeSample(point: CGPoint(x: startStroke.location.x + dx, y: startStroke.location.y + dy))
                    }
                    
                    stroke.set(samples: [startStroke, endStroke])
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

            // Redraw current stroke
            setNeedsDisplay()
        }
    }

    // MARK: -
    // MARK: rendering
    private func redrawBackground() {
        guard let pdf = delegate?.getBackgroundPdfURL() else { return }
        guard let page = CGPDFDocument(pdf as CFURL)?.page(at: 1) else { return }

        let pageRect = page.getBoxRect(.mediaBox)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: pageRect.width, height: pageRect.height))
        self.cachedBackground = renderer.image { ctx in
            // Draw background pdf
            UIColor.white.setFill()
            ctx.cgContext.interpolationQuality = .high
            ctx.cgContext.scaleBy(x: 1, y: -1)
            ctx.cgContext.translateBy(x: 0, y: -pageRect.height)
            ctx.cgContext.fill(pageRect)
            ctx.cgContext.drawPDFPage(page)

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
        }
    }

    private func invalidateHighQualityBackground() {
        self.highQualityBackground = nil
    }

    private func redrawHighQualityBackground() {
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
                ctx.clip(to: pageRect)

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
            }
            
            DispatchQueue.main.sync {
                self.setNeedsDisplay()
            }
        }
    }

    func fullRedraw() {
        redrawBackground()
        redrawHighQualityBackground()
    }

    override func draw(_ rect: CGRect) {
        // Do transforms
        guard let background = cachedBackground else { return }
        guard let pdf = delegate?.getBackgroundPdfURL() else { return }
        guard let page = CGPDFDocument(pdf as CFURL)?.page(at: 1) else { return }
        let pageRect = page.getBoxRect(.mediaBox)
        let context = UIGraphicsGetCurrentContext()!

        context.interpolationQuality = .default
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
        context.clip(to: pageRect)
        
        // draw active stroke
        for s in [delegate?.strokeCollection?.previousStroke, delegate?.strokeCollection?.activeStroke] {
            if let stroke = s {
                // Set stroke color
                stroke.color.setStroke()
                
                // Draw known part of stroke
                if let path = stroke.path {
                    path.lineCapStyle = .round
                    path.lineJoinStyle = .round
                    path.lineWidth = stroke.width
                    path.stroke()
                }
            }
        }
        context.restoreGState()
    }
}
