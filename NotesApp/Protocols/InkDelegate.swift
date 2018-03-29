//
//  InkDelegate.swift
//  NotesPro
//
//  Created by Dominik Horn on 07.02.18.
//  Copyright © 2018 Dominik Horn. All rights reserved.
//

import UIKit

protocol InkDelegate {
    var strokeCollection: StrokeCollection? { get set }

    var topOffset: CGFloat { get }
    
    func shouldInkFor(touch: UITouch) -> Bool
    
    func acceptActiveStroke()
    
    func getBackgroundPdfURL() -> URL?
}
