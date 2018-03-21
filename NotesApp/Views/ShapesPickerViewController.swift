//
//  ShapesPickerViewController.swift
//  NotesApp
//
//  Created by Dominik Horn on 17.03.18.
//  Copyright © 2018 Dominik Horn. All rights reserved.
//

import UIKit

class ShapesPickerViewController: UIViewController {
    @IBOutlet weak var snappingAngleLabel: UILabel!
    @IBOutlet weak var snappingSwitch: UISwitch!
    @IBOutlet weak var snappingStepper: UIStepper!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        snappingStepper.value = Double(snappingStep) * 180 / Double.pi
        snappingSwitch.isOn = shouldSnap
        snappingAngleLabel.text = String(format: "Snapping Angle %2.1fº", snappingStepper.value)
    }
    
    @IBAction func stepperChanged(_ sender: Any) {
        snappingStep = CGFloat(snappingStepper.value) * CGFloat.pi / 180
        snappingAngleLabel.text = String(format: "Snapping Angle %2.1fº", snappingStepper.value)
    }
    
    @IBAction func switchChanged(_ sender: Any) {
        shouldSnap = snappingSwitch.isOn
    }
    
    @IBAction func dismissManually(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
