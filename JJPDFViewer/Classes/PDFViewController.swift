//
//  PDFViewController.swift
//  JJPDFViewer
//
//  Created by weigege on 2020/12/11.
//

import Foundation

open class PDFViewController: UIViewController, PDFDocumentLoaderDelegate {
    
    var documentLoader: PDFDocumentLoader? {
        didSet {
            self.documentLoader?.delegate = self
        }
    }
    var loadingView: (UIView & PDFDocumentLoadingView)?
    
    public var pdfView: PDFView = .init(frame: .zero)
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
        self.documentLoader?.startLoading()
    }
    
    open func removeLoadingView() {
        self.loadingView?.removeFromSuperview()
    }
    
    open func showPDFView() {
        self.pdfView.isHidden = false
    }
    
    open func setup() {
        self.view.backgroundColor = .white
        self.view.addSubview(self.pdfView)
        if let loadingView = self.loadingView {
            self.view.addSubview(loadingView)
        }
        self.pdfView.isHidden = false
        self.loadingView?.isHidden = false
        self.layoutPDFView()
        self.layoutLoadingView()
    }
    
    open func layoutPDFView() {
        self.layout(view: self.pdfView, equalToEdgeOf: self.view)
    }
    
    open func layoutLoadingView() {
        guard let loadingView = self.loadingView else {
            return
        }
        self.layout(view: loadingView, equalToEdgeOf: self.view)
    }
    
    open func handleLoadingFailed(_ error: Error?) {
        print("Load document failed - error: \(error?.localizedDescription ?? "nil")")
    }
    
    open func handleLoadingSucceed(_ document: PDFDocument) {
        self.removeLoadingView()
        self.showPDFView()
        self.pdfView.document = document
    }
    
    // MARK: - PDFDocumentLoaderDelegate
    public func loader(_ loader: PDFDocumentLoader, didUpdateProgress progress: Float, fileInfo: PDFFileInfo) {
        self.loadingView?.update(progres: progress, fileInfo: fileInfo)
    }
    
    public func loader(_ loader: PDFDocumentLoader, didChangeState state: PDFDocumentLoadingState, result: PDFDocumentLoadingResult?) {
        self.loadingView?.refresh(with: state, result: result)
        if state == .completed {
            switch result {
            case .failure(let error):
                self.handleLoadingFailed(error)
            case .success(let document):
                self.handleLoadingSucceed(document)
            case .none:
                self.handleLoadingFailed(nil)
            }
        }
    }
}

private extension PDFViewController {
    
    func adddConstraint(to view: UIView, withItem item: Any, from: NSLayoutConstraint.Attribute, to: NSLayoutConstraint.Attribute) {
        view.translatesAutoresizingMaskIntoConstraints = false
        let constraint = NSLayoutConstraint(item: view, attribute: from, relatedBy: .equal, toItem: item, attribute: to, multiplier: 1.0, constant: 0.0)
        view.superview?.addConstraint(constraint)
    }
    
    func layout(view: UIView, equalToEdgeOf superView: UIView) {
        self.adddConstraint(to: view, withItem: self.topLayoutGuide, from: .top, to: .bottom)
        self.adddConstraint(to: view, withItem: self.bottomLayoutGuide, from: .bottom, to: .top)
        self.adddConstraint(to: view, withItem: superView, from: .leading, to: .leading)
        self.adddConstraint(to: view, withItem: superView, from: .trailing, to: .trailing)
    }
}
