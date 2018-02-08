//
//  FastPDFView.swift
//  NotesApp
//
//  Created by Dominik Horn on 09.02.18.
//  Copyright © 2018 Dominik Horn. All rights reserved.
//

import UIKit

class FastPDFView {
    var bounds: CGRect
    private var imgBuf: UIImage?
    
    init(bounds: CGRect) {
        self.bounds = bounds
    }
    
    func refresh(withPDF pdf: URL, scaleFac: CGFloat = 1.0) {
        var scale = scaleFac
        if scale < 1 {
            scale = 1
        } else if scale > 6 {
            scale = 6
        }
        
        if let page = CGPDFDocument(pdf as CFURL)?.page(at: 1) {
            let pageRect = page.getBoxRect(.mediaBox)
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: pageRect.width * scale, height: pageRect.height * scale))
            imgBuf = renderer.image { ctx in
                UIColor.white.setFill()
                ctx.cgContext.translateBy(x: 0, y: pageRect.height * scale)
                ctx.cgContext.scaleBy(x: scale, y: -scale)
                ctx.cgContext.fill(CGRect(x: 0, y: 0, width: pageRect.width * scale, height: pageRect.height * scale))
                ctx.cgContext.drawPDFPage(page)
            }
        }
    }
    
    func draw() {
        imgBuf?.draw(in: bounds)
    }
}
