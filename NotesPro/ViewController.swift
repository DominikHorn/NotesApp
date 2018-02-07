//
//  ViewController.swift
//  NotesPro
//
//  Created by Dominik Horn on 07.02.18.
//  Copyright © 2018 Dominik Horn. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet var inkview: InkView!
    
    // TODO: load this from actual model
    var strokes: [InkStroke] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set delegate of inkview
        inkview.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController: InkDelegate {
    func newStroke(start: CGPoint, sender: UIView?) {
        strokes.append(InkStroke(point: start, linewidth: 2, color: UIColor.blue))
        sender?.setNeedsDisplay()
    }
    
    func addPoint(point: CGPoint, sender: UIView?) {
        strokes[strokes.count-1].addPoint(point)
        sender?.setNeedsDisplay()
    }
    
    func endStroke(end: CGPoint, sender: UIView?) {
        strokes[strokes.count-1].addPoint(end)
        sender?.setNeedsDisplay()
    }
    
    func getStrokes(sender: UIView?) -> [InkStroke] {
        return strokes
    }
    
    func shouldFingerInk() -> Bool {
        return false
    }
}
