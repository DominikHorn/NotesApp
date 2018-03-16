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
            delegate?.updateContentSize(pageRect.size)
            setNeedsDisplay()
        }
    }
    
    // Whether or not to draw stroke prediction (Turning it on introduces horrible artifacts)
    var drawPredictedStroke = false
    
    // Timer used for handy straight line drawing feature
    var straightLineTimer: Timer?
    
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
            setNeedsDisplay()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if delegate?.shouldInkFor(touch: touches.first!) ?? false {
            straightLineTimer?.invalidate()

            // TODO: Figure out again why this happens ?? Clear the last stroke.
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
    func draw(stroke: Stroke, showPredicted: Bool = false) {
        if let path = stroke.path {
            stroke.color.setStroke()
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.lineWidth = stroke.width
            path.stroke()
        }
        
        // Draw predicted path if exists
        if let predictedPath = stroke.predictedPath {
            if showPredicted {
                predictedPath.lineCapStyle = .round
                predictedPath.lineJoinStyle = .round
                predictedPath.lineWidth = stroke.width
                predictedPath.stroke(with: .normal, alpha: 0.2)
            }
        }
    }
    
    
    // TODO: push into controller via delegate pattern
    func addSamples(for touches: [UITouch]) {
        if let stroke = delegate?.strokeCollection?.activeStroke {
            if stroke.isStraight {
                if let last = touches.last {
                    // TODO: will this break?
                    stroke.set(samples: [stroke.samples.first!, StrokeSample(point: last.preciseLocation(in: self))])
                }
            } else {
                // Add all of the touches to the active stroke.
                for touch in touches {
                    if touch == touches.last {
                        let sample = StrokeSample(point: touch.preciseLocation(in: self))
                        stroke.add(sample: sample)
                    } else {
                        // If the touch is not the last one in the array, it was a coalesced touch.
                        let sample = StrokeSample(point: touch.preciseLocation(in: self), coalesced: true)
                        stroke.add(sample: sample)
                    }
                }
            }

            // Redraw current stroke
            setNeedsDisplay()
        }
    }

    // TODO: push into controller via delegate pattern
    func setPredictionTouches(_ touches: [UITouch]) {
        if let stroke = delegate?.strokeCollection?.activeStroke {
            stroke.predictedSamples = []
            for touch in touches {
                let sample = StrokeSample(point: touch.preciseLocation(in: self))
                stroke.addPredicted(sample: sample)
            }
        }
    }
    
    override func draw(_ rect: CGRect) {
        // Do transforms
        guard let url = delegate?.getBackgroundPdfURL() else { return }
        guard let document = CGPDFDocument(url as CFURL) else { return }
        guard let page = document.page(at: 1) else { return }
        let pageRect = page.getBoxRect(.mediaBox)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.white.cgColor)
        context.fill(pageRect)
        //context.setShadow(offset: CGSize(width: 0, height: 5), blur: 10) // TODO: readd shadows
        context.drawPDFPage(page)
        //context.setShadow(offset: CGSize(width: 0, height: 0), blur: 0)
        context.clip(to: pageRect)
        
        // Draw all previous strokes
        self.delegate?.strokeCollection?.strokes.forEach() { draw(stroke: $0) }
        
        // Draw active stroke
        if let stroke = self.delegate?.strokeCollection?.activeStroke {
            draw(stroke: stroke, showPredicted: drawPredictedStroke)
        }
    }
}
