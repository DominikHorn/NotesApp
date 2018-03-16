//
//  InkDelegate.swift
//  NotesPro
//
//  Created by Dominik Horn on 07.02.18.
//  Copyright © 2018 Dominik Horn. All rights reserved.
//

import UIKit

protocol InkDelegate {
    // Storage for strokes
    var strokeCollection: StrokeCollection? { get set }
    
    // Whether or not inking should start for this touch
    func shouldInkFor(touch: UITouch) -> Bool
    
    // Notification that view has determinded that stroke is finished
    func acceptActiveStroke()
    
    // makes sure that views size gets updated to new content size
    func updateContentSize(_ size: CGSize)
    
    // Obtain background pdf URL
    func getBackgroundPdfURL() -> URL?
}
