//
//  ColorPickerViewController.swift
//  NotesApp
//
//  Created by Dominik Horn on 08.02.18.
//  Copyright © 2018 Dominik Horn. All rights reserved.
//

import UIKit

class PencilPickerViewController: UIViewController {
    @IBOutlet weak var redSlider: UISlider!
    @IBOutlet weak var greenSlider: UISlider!
    @IBOutlet weak var blueSlider: UISlider!
    @IBOutlet weak var widthSlider: UISlider!
    @IBOutlet weak var redLabel: UILabel!
    @IBOutlet weak var greenLabel: UILabel!
    @IBOutlet weak var blueLabel: UILabel!
    @IBOutlet weak var widthLabel: UILabel!
    @IBOutlet weak var widthDisplay: UIView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // TODO: sync with documentViewController
        update()
    }
    
    // MARK: -
    // MARK: UIActions
    @IBAction func sliderChanged(_ sender: UISlider) {
        currentColor = UIColor(red: CGFloat(redSlider.value), green: CGFloat(greenSlider.value), blue: CGFloat(blueSlider.value), alpha: 1.0)
        currentLineWidth = CGFloat(widthSlider.value)
        update()
    }
    
    @IBAction func dismissManually(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: -
    // MARK: helper
    func update(_ animated: Bool = false) {
        if let colors = currentColor.cgColor.components {
            redSlider.setValue(Float(colors[0]), animated: animated)
            greenSlider.setValue(Float(colors[1]), animated: animated)
            blueSlider.setValue(Float(colors[2]), animated: animated)
            redLabel.text = "Red \(Int(colors[0] * 255))"
            greenLabel.text = "Green \(Int(colors[1] * 255))"
            blueLabel.text = "Blue \(Int(colors[2] * 255))"
        }
        
        widthSlider.setValue(Float(currentLineWidth), animated: animated)
        widthLabel.text = String(format: "Width %.1f", Float(currentLineWidth))
        widthDisplay.setNeedsDisplay()
    }
}
