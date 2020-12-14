//
//  PDFDocumentLoader.swift
//  JJPDFViewer
//
//  Created by weigege on 2020/12/11.
//

import Foundation

public protocol PDFFileInfo {
    
    var downloaded: Int64 { get }
    var fileSize: Int64 { get }
}

public enum PDFDocumentLoadingResult {

    case success(_ document: PDFDocument)
    case failure(_ error: Error?)
}

public struct PDFDocumentLoadingState: RawRepresentable, Equatable {
    
    static let unstarted: PDFDocumentLoadingState = .init(raw: 0)
    static let loading: PDFDocumentLoadingState = .init(raw: 1)
    static let completed: PDFDocumentLoadingState = .init(raw: 2)
    
    public var rawValue: Int

    public init?(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public init(raw: Int) {
        self.rawValue = raw
    }
}

extension PDFDocumentLoadingState {
    
    static let some: PDFDocumentLoadingState = .init(raw: 3)
}

public protocol PDFDocumentLoaderDelegate: AnyObject {
    
    func loader(_ loader: PDFDocumentLoader, didUpdateProgress progress: Float, fileInfo: PDFFileInfo)
    func loader(_ loader: PDFDocumentLoader, didChangeState state: PDFDocumentLoadingState, result: PDFDocumentLoadingResult?)
}

public protocol PDFDocumentLoader: AnyObject {
    
    /// Make sure 'delegate' is a weak property.
    var delegate: PDFDocumentLoaderDelegate? { get set }
    
    func startLoading()
}
