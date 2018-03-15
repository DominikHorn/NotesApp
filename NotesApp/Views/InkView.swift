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
            // Center page initially
            guard let pdf = delegate?.getBackgroundPdfURL() else { return }
            guard let page = CGPDFDocument(pdf as CFURL)?.page(at: 1) else { return }
            
            let pageRect = page.getBoxRect(.mediaBox)
            inkTransform = CGAffineTransform(translationX: self.bounds.width/2 - pageRect.width/2, y: 0)
            fullRedraw()
        }
    }
    
    // Whether or not to draw stroke prediction (Turning it on introduces horrible artifacts)
    var drawPredictedStroke = false
    
    // Cached rendering for greatly increased performance
    var cachedBackground: UIImage?
    var highQualityBackground: UIImage?

    // Timer used for handy straight line drawing feature
    var straightLineTimer: Timer?
    
    // Transformation to properly center the ink TODO: remove this as is should be unnecessary
    var inkTransform: CGAffineTransform = CGAffineTransform(translationX: 0, y: 0)
    
    // MARK: -
    // MARK: init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        // Setup view
        self.layer.drawsAsynchronously = true
        self.isMultipleTouchEnabled = true
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
        if delegate?.shouldInkFor(touch: touches.first!) ?? false {
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
        if delegate?.shouldInkFor(touch: touches.first!) ?? false {
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

            if let predicted = event?.predictedTouches(for: touches.first!) {
                setPredictionTouches(predicted)
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if delegate?.shouldInkFor(touch: touches.first!) ?? false {
            straightLineTimer?.invalidate()

            // Accept the active stroke.
            delegate?.acceptActiveStroke()
            fullRedraw() // TODO observer pattern/push to controller
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if delegate?.shouldInkFor(touch: touches.first!) ?? false {
            straightLineTimer?.invalidate()

            // TODO: Why?? Clear the last stroke.
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
    
    // TODO: should this really be view? probably not -> push into controller via delegate pattern
    func addSamples(for touches: [UITouch]) {
        if let stroke = delegate?.strokeCollection?.activeStroke {
            if stroke.isStraight {
                if let last = touches.last {
                    // TODO: will this break?
                    stroke.set(samples: [stroke.samples.first!, StrokeSample(point: last.preciseLocation(in: self).applying(inkTransform.inverted()))])
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

    // TODO push into controller via delegate pattern
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
    private func redrawBackground() {
        guard let pdf = delegate?.getBackgroundPdfURL() else { return }
        guard let page = CGPDFDocument(pdf as CFURL)?.page(at: 1) else { return }

        let pageRect = page.getBoxRect(.mediaBox)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: pageRect.width*2, height: pageRect.height*2))
        self.cachedBackground = renderer.image { ctx in
            // Draw background pdf
            UIColor.white.setFill()
            ctx.cgContext.interpolationQuality = .high
            ctx.cgContext.scaleBy(x: 2, y: -2)
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

    // TODO rework
    private func invalidateHighQualityBackground() {
        self.highQualityBackground = nil
    }

    // TODO rework
    private func redrawHighQualityBackground() {
        // TODO: handle with controller
        /*// Render high quality section of pdf background
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
            
            DispatchQueue.main.async {
                self.setNeedsDisplay()
            }
        }*/
    }

    // TODO: rework (maybe have setDirty() method that will redraw both in background thread)
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
        context.concatenate(inkTransform)
        context.setShadow(offset: CGSize(width: 0, height: 5), blur: 10)
        context.draw(background.cgImage!, in: pageRect)
        context.setShadow(offset: CGSize(width: 0, height: 0), blur: 0) // TODO better way to disable shadows
        // TODO rework
        if let hqBackground = highQualityBackground {
            context.draw(hqBackground.cgImage!, in: bounds)
        }
        context.clip(to: pageRect)

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
                if drawPredictedStroke {
                    predictedPath.lineCapStyle = .round
                    predictedPath.lineJoinStyle = .round
                    predictedPath.lineWidth = stroke.width
                    predictedPath.stroke(with: .normal, alpha: 0.2)
                }
            }
        }
        context.restoreGState()
    }
}
