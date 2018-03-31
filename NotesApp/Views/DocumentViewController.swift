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
    @IBOutlet weak var inkScrollView: UIScrollView!
    @IBOutlet weak var undoBarButton: UIBarButtonItem!
    @IBOutlet weak var redoBarButton: UIBarButtonItem!
    
    @IBOutlet weak var inkViewWidth: NSLayoutConstraint!
    @IBOutlet weak var inkViewHeight: NSLayoutConstraint!
    
    // Touch types that trigger inking
    var inkSources = [UITouchType.stylus]
    
    var strokeCollection: StrokeCollection?
    var undoman: UndoManager
    
    var document: Document?
    
    // MARK: -
    // MARK: Lifecycle
    required init?(coder aDecoder: NSCoder) {
        strokeCollection = StrokeCollection()
        undoman = UndoManager()
        
        super.init(coder: aDecoder)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make sure to correctly setup the delegate
        inkView.delegate = self
        
        // Add undo tap recognizer TODO: rework
        /*let undoRecog = UITapGestureRecognizer(target: self, action: #selector(tappedToUndo))
        undoRecog.numberOfTapsRequired = 1
        undoRecog.numberOfTouchesRequired = 2
        inkView.addGestureRecognizer(undoRecog)*/
        
        // Setup scrollview
        inkScrollView.panGestureRecognizer.allowedTouchTypes = [UITouchType.direct.rawValue as NSNumber, UITouchType.indirect.rawValue as NSNumber]
        inkScrollView.contentInset = UIEdgeInsets(top: 0, left: 50, bottom: 0, right: 50)
        inkScrollView.decelerationRate = UIScrollViewDecelerationRateFast
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

// MARK: -
// MARK: InkDelegate remainder
extension DocumentViewController {
    func shouldInkFor(touch: UITouch) -> Bool {
        return inkSources.contains(touch.type)
    }
    
    func updateContentSize(_ size: CGSize) {
        // Update content view size by updating constraints
        inkViewWidth.constant = size.width
        inkViewHeight.constant = size.height
        
        // Update scrollview content size
        inkScrollView.contentSize = size
        
        // Center content view within scrollview
        //inkView.centerXAnchor.constraint(equalTo: inkScrollView.contentLayoutGuide.centerXAnchor)
        //inkView.centerYAnchor.constraint(equalTo: inkScrollView.contentLayoutGuide.centerYAnchor)
    }
    
    func acceptActiveStroke() {        
        undoman.registerUndo(withTarget: self) { $0.deleteLastStroke() }
        if !undoman.isRedoing {
            undoman.setActionName("Add stroke")
        }
        
        undoBarButton.isEnabled = true
        redoBarButton.isEnabled = undoman.canRedo
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
    
    func getBackgroundPdfURL() -> URL? {
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


// MARK: -
// MARK: UIScrollViewDelegate
extension DocumentViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return inkView
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        inkView.update(contentScale: scrollView.zoomScale)
    }
}

