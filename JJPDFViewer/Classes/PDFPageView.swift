//
//  PDFPageView.swift
//  JJPDFViewer
//
//  Created by weigege on 2020/12/8.
//

import UIKit

open class PDFPageView: UIView {

    open var page: CGPDFPage? {
        didSet {
            self.pageLayer.page = self.page
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.pageLayer.redraw()
    }
    
    open override var frame: CGRect {
        didSet {
            self.pageLayer.redraw()
        }
    }
    
    open override class var layerClass: AnyClass {
        return PDFPageLayer.classForCoder()
    }
}

public extension PDFPageView {
    
    var pageLayer: PDFPageLayer {
        return self.layer as! PDFPageLayer
    }
}
