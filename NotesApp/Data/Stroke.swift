//
//  InkStroke.swift
//  NotesPro
//
//  Created by Dominik Horn on 07.02.18.
//  Copyright © 2018 Dominik Horn. All rights reserved.
//

import UIKit

// TODO: rework, should come from a central place in app
var currentColor = UIColor.blue

struct StrokeSample {
    let location: CGPoint
    let coalescedSample: Bool
    
    init(point: CGPoint, coalesced: Bool = false) {
        location = point
        coalescedSample = coalesced
    }
}

class Stroke {
    var samples = [StrokeSample]()
    var predictedSamples = [StrokeSample]()
    var width: CGFloat
    var color: UIColor
    
    init(linewidth: CGFloat, color: UIColor) {
        self.width = linewidth
        self.color = color
    }
    
    func addPredicted(sample: StrokeSample) {
        predictedSamples.append(sample)
    }
    
    func add(sample: StrokeSample) {
        samples.append(sample)
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
        let stroke = strokes.last
        strokes.removeLast()
        return stroke
    }
}
