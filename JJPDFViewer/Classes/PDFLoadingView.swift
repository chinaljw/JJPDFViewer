//
//  PDFLoadingView.swift
//  JJPDFViewer
//
//  Created by weigege on 2020/12/11.
//

import Foundation

protocol PDFDocumentLoadingView {
    
    func refresh(with state: PDFDocumentLoadingState, result: PDFDocumentLoadingResult?)
    func update(progres: Float, fileInfo: PDFFileInfo)
}
