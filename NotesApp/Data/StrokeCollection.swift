//
//  StrokeCollection.swift
//  NotesApp
//
//  Created by Dominik Horn on 21.03.18.
//  Copyright © 2018 Dominik Horn. All rights reserved.
//

import Foundation

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
        previousStroke = nil
        
        if strokes.count > 0 {
            return strokes.removeLast()
        }
        
        return nil
    }
}
