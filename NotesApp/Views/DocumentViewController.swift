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
    @IBOutlet weak var inkScrollView: InkScrollView!
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
        
        let tapRecog = UITapGestureRecognizer(target: self, action: #selector(tappedToUndo))
        tapRecog.numberOfTapsRequired = 1
        tapRecog.numberOfTouchesRequired = 2
        inkView.addGestureRecognizer(tapRecog)
        
        // Setup scrollview
        inkScrollView.panGestureRecognizer.allowedTouchTypes = [UITouchType.direct.rawValue as NSNumber]
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
    func setScrollViewEnabled(bool: Bool) {
        inkScrollView.isScrollEnabled = bool
        inkScrollView.pinchGestureRecognizer?.isEnabled = bool
        
        
        // Stop scroll view from scrolling
        if !bool {
            inkScrollView.setContentOffset(inkScrollView.contentOffset, animated: false)
        }
    }
    
    func shouldInkFor(touch: UITouch) -> Bool {
        return inkSources.contains(touch.type)
    }
    
    func updateContentSize(_ size: CGSize) {
        inkScrollView.contentSize = size
        inkViewWidth.constant = size.width
        inkViewHeight.constant = size.height
        inkScrollView.setNeedsLayout()
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
        // TODO: implement
    }
}

