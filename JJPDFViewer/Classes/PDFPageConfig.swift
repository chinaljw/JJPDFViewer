//
//  PDFPageConfig.swift
//  JJPDFViewer
//
//  Created by weigege on 2020/12/10.
//

import Foundation

public protocol PDFPageConfig: AnyObject {

    var maximumZoomScale: CGFloat { get set }
    var pageBackgroundColor: UIColor { get set }
    var doubleTapToZoom: Bool { get set }
}

public extension PDFPageConfig {
    
    func fill(with config: PDFPageConfig) {
        self.maximumZoomScale = config.maximumZoomScale
        self.pageBackgroundColor = config.pageBackgroundColor
        self.doubleTapToZoom = config.doubleTapToZoom
    }
}
