//
//  PDFDocument.swift
//  JJPDFViewer
//
//  Created by weigege on 2020/12/8.
//

import Foundation

@objcMembers
open class PDFDocument: NSObject {
    
    public let raw: CGPDFDocument
    
    public init(_ raw: CGPDFDocument) {
        self.raw = raw
        super.init()
    }
}

// MARK: - Convenience Inits
public extension PDFDocument {
    
    convenience init?(fileURL: URL) {
        guard let document = CGPDFDocument(fileURL as CFURL) else {
            return nil
        }
        self.init(document)
    }
    
    convenience init?(pdfData: Data) {
        guard
            let provider = CGDataProvider(data: pdfData as CFData),
            let document = CGPDFDocument(provider)
        else {
            return nil
        }
        self.init(document)
    }
}

// MARK: -
public extension PDFDocument {
    
    var numberOfPages: Int {
        return self.raw.numberOfPages
    }
    
    func page(of index: Int) -> CGPDFPage? {
        return self.raw.page(at: index)
    }
}
