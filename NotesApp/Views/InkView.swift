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
            // Update size of view
            guard let pdf = delegate?.getBackgroundPdfURL() else { return }
            guard let page = CGPDFDocument(pdf as CFURL)?.page(at: 1) else { return }
            let pageRect = page.getBoxRect(.mediaBox)
            delegate?.updateContentSize(pageRect.size)
            
            // Redraw
            setNeedsDisplay()
        }
    }
    
    // Transform necessary since pdfs are rendered upside down
    var pdfTransform = CGAffineTransform()
    
    override var bounds: CGRect {
        didSet {
            pdfTransform = CGAffineTransform(translationX: 0, y: bounds.height).scaledBy(x: 1, y: -1)
        }
    }
    
    // Timer used for handy straight line drawing feature
    var straightLineTimer: Timer?
    
    // MARK: -
    // MARK: init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        // Setup view
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

            addSamples(for: [touches.first!])
            if let coalesced = event?.coalescedTouches(for: touches.first!) {
                addSamples(for: coalesced)
            }

            restartStraightLineTimer()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if delegate?.shouldInkFor(touch: touches.first!) ?? false {
            if let prevloc = touches.first?.precisePreviousLocation(in: self).applying(pdfTransform.inverted()) {
                if let loc = touches.first?.preciseLocation(in: self) {
                    if (loc.x - prevloc.x)*(loc.x - prevloc.x) + (loc.y - prevloc.y)*(loc.y - prevloc.y) > 0.1 {
                        restartStraightLineTimer()
                    }
                }
            }

            if let coalesced = event?.coalescedTouches(for: touches.first!) {
                addSamples(for: coalesced)
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if delegate?.shouldInkFor(touch: touches.first!) ?? false {
            straightLineTimer?.invalidate()

            // Accept the active stroke.
            delegate?.acceptActiveStroke()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if delegate?.shouldInkFor(touch: touches.first!) ?? false {
            straightLineTimer?.invalidate()

            // Delete active stroke
            delegate?.strokeCollection?.activeStroke = nil
            
            // Redraw view to remove last stroke
            setNeedsDisplay()
        }
    }

    // MARK: -
    // MARK: helper
    func update(contentScale: CGFloat) {
        print("UPDATE CONTENT SCALE")
        layer.contentsScale = contentScale
        setNeedsDisplay()
    }
    
    // TODO: push into controller via delegate pattern
    func addSamples(for touches: [UITouch]) {
        if let stroke = delegate?.strokeCollection?.activeStroke {
            if stroke.isStraight {
                if let last = touches.last {
                    // TODO: will this break?
                    stroke.set(samples: [stroke.samples.first!, StrokeSample(point: last.preciseLocation(in: self).applying(pdfTransform.inverted()), pressure: 1.0)])
                }
            } else {
                // Add all of the touches to the active stroke.
                for touch in touches {
                    if touch == touches.last {
                        let sample = StrokeSample(point: touch.preciseLocation(in: self).applying(pdfTransform.inverted()), pressure: 1.0)
                        stroke.add(sample: sample)
                    } else {
                        // If the touch is not the last one in the array, it was a coalesced touch.
                        let sample = StrokeSample(point: touch.preciseLocation(in: self).applying(pdfTransform.inverted()), pressure: 1.0, coalesced: true)
                        stroke.add(sample: sample)
                    }
                }
            }

            // Redraw current stroke
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        guard let url = delegate?.getBackgroundPdfURL() else { return }
        guard let document = CGPDFDocument(url as CFURL) else { return }
        guard let page = document.page(at: 1) else { return }
        let pageRect = page.getBoxRect(.mediaBox)
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.fill(pageRect)
        ctx.concatenate(pdfTransform)
        //ctx.clip(to: layer.bounds)
        
        ctx.drawPDFPage(page)
        
        // Draw all previous strokes
        self.delegate?.strokeCollection?.strokes.forEach() { $0.draw(inRect: pageRect, withContext: ctx) }
        
        // Draw active stroke
        if let stroke = self.delegate?.strokeCollection?.activeStroke {
            stroke.draw(inRect: pageRect, withContext: ctx)
        }
    }
}
