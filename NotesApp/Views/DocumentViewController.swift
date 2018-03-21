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
    var undomanager: UndoManager
    var currentModalVC: UIViewController?
    
    var document: Document?
    
    // MARK: -
    // MARK: initializing
    required init?(coder aDecoder: NSCoder) {
        strokeCollection = StrokeCollection()
        undomanager = UndoManager()
        
        super.init(coder: aDecoder)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make sure to correctly setup the delegate
        inkView.delegate = self
        
        let tapRecog = UITapGestureRecognizer(target: self, action: #selector(tappedToUndo))
        tapRecog.numberOfTapsRequired = 1
        tapRecog.numberOfTouchesRequired = 2
        inkView.addGestureRecognizer(tapRecog)
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
    
    @objc func tappedToUndo() {
        undo(nil)
    }
    
    @IBAction func undo(_ sender: UIBarButtonItem?) {
        undomanager.undo()
        
        // Manage disabling and enabling buttons
        if !undomanager.canUndo {
            undoBarButton.isEnabled = false
        }
        redoBarButton.isEnabled = true
    }
    
    @IBAction func redo(_ sender: UIBarButtonItem?) {
        undomanager.redo()
        
        // Manage disabling and enabling buttons
        if !undomanager.canRedo {
            redoBarButton.isEnabled = false
        }
        undoBarButton.isEnabled = true
    }
    
    // MARK: -
    // MARK: View controller handeling
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        if let cmvc = currentModalVC {
            cmvc.dismiss(animated: false, completion: nil)
        }
        currentModalVC = viewControllerToPresent
        
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }
}

// MARK: -
// MARK: InkDelegate impl
extension DocumentViewController {
    func shouldInkFor(touch: UITouch) -> Bool {
        return [UITouchType.stylus].contains(touch.type)
    }
    
    func acceptActiveStroke() {        
        undomanager.registerUndo(withTarget: self) { $0.deleteLastStroke() }
        if !undomanager.isRedoing {
            undomanager.setActionName("Add stroke")
        }
        
        undoBarButton.isEnabled = true
        redoBarButton.isEnabled = undomanager.canRedo
        strokeCollection?.acceptActiveStroke()
        inkView.fullRedraw()
    }
    
    func deleteLastStroke() {
        let deletedStroke = strokeCollection?.deleteLastStroke()
        undomanager.registerUndo(withTarget: self) { $0.strokeCollection?.activeStroke = deletedStroke; $0.acceptActiveStroke() }
        if !undomanager.isUndoing {
            undomanager.setActionName("Remove last stroke")
        }
        
        redoBarButton.isEnabled = true
        inkView.fullRedraw()
    }
    
    func getBackgroundPdfURL() -> URL? {
        // TODO: change this based on page
        return document?.pdfURL
    }
}

// MARK: -
// MARK: UIBarPositioningDelegate
extension DocumentViewController: UIBarPositioningDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
