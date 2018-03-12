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
    // Staged samples have not yet been displayed
    private var stagedSamples = [StrokeSample]()
    var predictedSamples = [StrokeSample]()
    var width: CGFloat
    var color: UIColor
    
    private var pathStore: UIBezierPath?
    fileprivate var pathIsDirty: Bool = false
    var path: UIBezierPath? {
        get {
            if pathIsDirty {
                pathStore = calculatePath(samples: stagedSamples)
                samples = stagedSamples
            }
            
            return pathStore
        }
    }
    var predictedPath: UIBezierPath? {
        get {
            return calculatePath(samples: [samples[samples.count-1]] + predictedSamples)
        }
    }
    
    init(linewidth: CGFloat, color: UIColor) {
        self.width = linewidth
        self.color = color
    }
    
    func addPredicted(sample: StrokeSample) {
        predictedSamples.append(sample)
    }
    
    func add(sample: StrokeSample) {
        stagedSamples.append(sample)
        
        // Force Path to update on next retrieval
        pathIsDirty = true
    }
    
    private func calculatePath(samples: [StrokeSample]) -> UIBezierPath {
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
    
    func acceptActiveStroke() {
        if let stroke = activeStroke {
            stroke.pathIsDirty = false
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
