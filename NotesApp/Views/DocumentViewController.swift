//
//  DocumentViewController.swift
//  NotesApp
//
//  Created by Dominik Horn on 08.02.18.
//  Copyright © 2018 Dominik Horn. All rights reserved.
//

import UIKit

class DocumentViewController: UIViewController, InkDelegate {
    @IBOutlet weak var inkView: InkView!
    
    var strokeCollection: StrokeCollection?
    
    var document: UIDocument?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        strokeCollection = StrokeCollection()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        inkView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Access the document
        document?.open(completionHandler: { (success) in
            if success {
                // Display the content of the document, e.g.:
                //self.documentNameLabel.text = self.document?.fileURL.lastPathComponent
            } else {
                // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
            }
        })
    }
    
    @IBAction func dismissDocumentViewController() {
        dismiss(animated: true) {
            self.document?.close(completionHandler: nil)
        }
    }
}
