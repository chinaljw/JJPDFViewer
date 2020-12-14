//
//  PDFViewController.swift
//  JJPDFViewer
//
//  Created by weigege on 2020/12/12.
//

import Foundation

public class PDFSimpleViewController: PDFViewController {
    
    public convenience init(url: URL?) {
        self.init()
        self.documentLoader = Loader(url: url)
        self.loadingView = LoadingView(frame: .zero)
    }
    
    public convenience init(urlString: String) {
        self.init(url: URL(string: urlString))
    }
    
    public convenience init(filePath: String) {
        self.init(url: .init(fileURLWithPath: filePath))
    }
}
