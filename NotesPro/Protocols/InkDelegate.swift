//
//  InkDelegate.swift
//  NotesPro
//
//  Created by Dominik Horn on 07.02.18.
//  Copyright © 2018 Dominik Horn. All rights reserved.
//

import UIKit

protocol InkDelegate {
    func newStroke(start: CGPoint, sender: UIView?)
    func addPoint(point: CGPoint, sender: UIView?)
    func endStroke(end: CGPoint, sender: UIView?)
    
    func shouldFingerInk() -> Bool
    
    func getStrokes(sender: UIView?) -> [InkStroke]
}
