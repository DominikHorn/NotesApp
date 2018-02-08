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
    @IBOutlet weak var undoBarButton: UIBarButtonItem!
    @IBOutlet weak var redoBarButton: UIBarButtonItem!
    
    var strokeCollection: StrokeCollection?
    var undoman: UndoManager
    
    var document: UIDocument?
    
    // MARK: -
    // MARK: initializing
    required init?(coder aDecoder: NSCoder) {
        strokeCollection = StrokeCollection()
        undoman = UndoManager()
        
        super.init(coder: aDecoder)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make sure to correctly setup the delegate
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
    
    // MARK: -
    // MARK: UI Actions
    @IBAction func dismissDocumentViewController() {
        dismiss(animated: true) {
            self.document?.close(completionHandler: nil)
        }
    }
    
    @IBAction func undo(_ sender: UIBarButtonItem?) {
        undoman.undo()
        
        // Manage disabling and enabling buttons
        if !undoman.canUndo {
            undoBarButton.isEnabled = false
        }
        redoBarButton.isEnabled = true
    }
    
    @IBAction func redo(_ sender: UIBarButtonItem?) {
        undoman.redo()
        
        // Manage disabling and enabling buttons
        if !undoman.canRedo {
            redoBarButton.isEnabled = false
        }
        undoBarButton.isEnabled = true
    }
}

extension DocumentViewController {
    func acceptActiveStroke() {
        undoman.registerUndo(withTarget: self) { $0.deleteLastStroke() }
        if !undoman.isRedoing {
            undoman.setActionName("Add stroke")
        }
        
        undoBarButton.isEnabled = true
        strokeCollection?.acceptActiveStroke()
        inkView.setNeedsDisplay()
    }
    
    func deleteLastStroke() {
        let deletedStroke = strokeCollection?.deleteLastStroke()
        undoman.registerUndo(withTarget: self) { $0.strokeCollection?.activeStroke = deletedStroke; $0.acceptActiveStroke() }
        if !undoman.isUndoing {
            undoman.setActionName("Remove last stroke")
        }
        
        redoBarButton.isEnabled = true
        inkView.setNeedsDisplay()
    }
}
