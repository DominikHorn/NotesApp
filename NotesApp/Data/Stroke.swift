//
//  InkStroke.swift
//  NotesPro
//
//  Created by Dominik Horn on 07.02.18.
//  Copyright © 2018 Dominik Horn. All rights reserved.
//

import UIKit

struct StrokeSample {
    let location: CGPoint
    var pressure: CGFloat
    let coalescedSample: Bool
    
    init(point: CGPoint, pressure: CGFloat, coalesced: Bool = false) {
        self.location = point
        self.pressure = pressure
        self.coalescedSample = coalesced
    }
}

class Stroke {
    // Samples are actual samples that the user saw
    var samples = [StrokeSample]()
    var bounds: CGRect
    var width: CGFloat
    var color: UIColor
    var isStraight: Bool = false
    
    init(linewidth: CGFloat, color: UIColor) {
        self.width = linewidth
        self.color = color
        self.bounds = CGRect()
    }
    
    func add(sample: StrokeSample) {
        samples.append(sample)
        
        // Update bounds
        if sample.location.x < bounds.minX {
            bounds.origin.x = sample.location.x
        }
        if sample.location.x > bounds.maxX {
            bounds.size.width = sample.location.x - bounds.origin.x
        }
        if sample.location.y < bounds.minY {
            bounds.origin.y = sample.location.y
        }
        if sample.location.y > bounds.maxY {
            bounds.size.height = sample.location.y - bounds.origin.y
        }
    }
    
    func set(samples: [StrokeSample]) {
        self.samples = samples
    }
    
    // TODO: only attempt to draw stroke if it can actually be seen on screen
    func draw(inRect rect: CGRect, withContext ctx: CGContext?, minPressure: CGFloat = 0.6, maxPressure: CGFloat = 1.1, maxPressureChange: CGFloat = 0.015) {
        if bounds.intersects(rect) {
            ctx?.setStrokeColor(self.color.cgColor)
            ctx?.setLineCap(.round)
            ctx?.setLineJoin(.round)
            
            if samples.count > 0 {
                var pressure: CGFloat = samples[0].pressure
                ctx?.setLineWidth(pressure * width)
                ctx?.move(to: samples[0].location)
                for i in 0..<(samples.count-1) {
                    let s1 = samples[i+1]
                    if s1.pressure - pressure > maxPressureChange {
                        pressure += maxPressureChange
                    } else if s1.pressure - pressure < -maxPressureChange {
                        pressure -= maxPressureChange
                    } else {
                        pressure = s1.pressure
                    }
                    if pressure < minPressure {
                        pressure = minPressure
                    }
                    if pressure > maxPressure {
                        pressure = maxPressure
                    }
                    ctx?.setLineWidth(pressure * width)
                    
                    ctx?.addLine(to: s1.location)
                    ctx?.strokePath()
                    ctx?.move(to: s1.location)
                }
            }
        }
    }
}


class StrokeCollection {
    var strokes = [Stroke]()
    var activeStroke: Stroke? = nil
    
    func acceptActiveStroke() {
        if let stroke = activeStroke {
            strokes.append(stroke)
            activeStroke = nil
        }
    }
    
    func deleteLastStroke() -> Stroke? {
        if strokes.count > 0 {
            return strokes.removeLast()
        }
        
        return nil
    }
}
