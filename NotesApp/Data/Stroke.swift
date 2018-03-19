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
    let coalescedSample: Bool
    
    init(point: CGPoint, coalesced: Bool = false) {
        location = point
        coalescedSample = coalesced
    }
}

class Stroke {
    // Samples are actual samples that the user saw
    var samples = [StrokeSample]()
    var width: CGFloat
    var color: UIColor
    var isStraight: Bool = false
    
    private var pathStore: UIBezierPath?
    var path: UIBezierPath?
    
    init(linewidth: CGFloat, color: UIColor) {
        self.width = linewidth
        self.color = color
    }
    
    func add(sample: StrokeSample) {
        samples.append(sample)
        
        if let p = path {
            p.addLine(to: sample.location)
        } else {
            path = UIBezierPath()
            path?.move(to: sample.location)
        }
    }
    
    func set(samples: [StrokeSample]) {
        self.samples = samples
        path = calculatePath(samples: self.samples)
    }
    
    func calculatePath(samples: [StrokeSample]) -> UIBezierPath {
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

class StrokeCollection {
    var strokes = [Stroke]()
    var activeStroke: Stroke? = nil
    var previousStroke: Stroke? = nil
    
    func acceptActiveStroke() {
        if let stroke = activeStroke {
            strokes.append(stroke)
            previousStroke = activeStroke
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
