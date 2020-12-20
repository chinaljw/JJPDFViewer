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
            guard self.page != oldValue else {
                return
            }
            self.pageLayer.page = self.page
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


