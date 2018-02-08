//
//  ColorPickerViewController.swift
//  NotesApp
//
//  Created by Dominik Horn on 08.02.18.
//  Copyright © 2018 Dominik Horn. All rights reserved.
//

import UIKit

class ColorPickerViewController: UIViewController, ColorPickerDelegate {
    @IBOutlet weak var redSlider: UISlider!
    @IBOutlet weak var greenSlider: UISlider!
    @IBOutlet weak var blueSlider: UISlider!
    @IBOutlet weak var colorDisplay: UIView!
    
    var currentColor: UIColor {
        set {
            colorUpdated()
        }
        get {
            return self.currentColor
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // TODO: sync with documentViewController
        currentColor = UIColor.green
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        colorUpdated(true)
    }
    
    // MARK: -
    // MARK: UIActions
    @IBAction func sliderChanged(_ sender: UISlider) {
        currentColor = UIColor(red: CGFloat(redSlider.value), green: CGFloat(greenSlider.value), blue: CGFloat(blueSlider.value), alpha: 1.0)
    }
    
    // MARK: -
    // MARK: helper
    func colorUpdated(_ animated: Bool = false) {
        if let colors = currentColor.cgColor.components {
            redSlider.setValue(Float(colors[0] * 255), animated: animated)
            greenSlider.setValue(Float(colors[1] * 255), animated: animated)
            blueSlider.setValue(Float(colors[2] * 255), animated: animated)
        }
        
        colorDisplay.backgroundColor = currentColor
        colorDisplay.setNeedsDisplay()
    }
}
