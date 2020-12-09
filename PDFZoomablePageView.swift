//
//  PDFZoomablePageView.swift
//  JJPDFViewer
//
//  Created by weigege on 2020/12/8.
//

import UIKit

open class PDFZoomablePageView: UIView {
    
    private static let uninitialFrame: CGRect = .init(origin: .zero,
                                              size: .init(width: -1.0, height: -1.0))
    
    public let scrollView: UIScrollView = .init(frame: .zero)
    public let pageView: PDFPageView = .init(frame: uninitialFrame)
    public var isDoubleTapZoomingEnable: Bool = true
    
    public var page: CGPDFPage? {
        set {
            self.pageView.page = newValue
            self.relayout()
        }
        get {
            return self.pageView.page
        }
    }
    
    open override var frame: CGRect {
        didSet {
            self.relayoutIfNeeded()
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.relayoutIfNeeded()
    }
}

private extension PDFZoomablePageView {
    
    func setup() {
        self.addSubview(self.scrollView)
        self.scrollView.maximumZoomScale = 4
        self.scrollView.minimumZoomScale = 1
        self.scrollView.delegate = self
        self.scrollView.addSubview(self.pageView)
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.showsVerticalScrollIndicator = false
    }
    
    func relayout() {
//        print("relayout begin - scrollView: \(self.scrollView), bounds: \(self.bounds)")
        self.scrollView.frame = self.bounds
//        print("relayout willChangeScale - scrollView: \(self.scrollView), bounds: \(self.bounds)")
        self.scrollView.zoomScale = 1.0
        if let page = self.page {
//            print("relayout setting - scrollView: \(self.scrollView), bounds: \(self.bounds)")
            let fitSize = self.fitSize(for: page)
            self.pageView.frame.size = self.fitSize(for: page)
            self.pageView.center = self.scrollView.center
            self.scrollView.contentSize = fitSize
//            print("relayout finish - scrollView: \(self.scrollView), bounds: \(self.bounds)")
        } else {
            self.pageView.frame = Self.uninitialFrame
        }
    }
    
    func relayoutIfNeeded() {
        guard
            self.scrollView.frame.size != self.bounds.size
            || self.pageView.frame == Self.uninitialFrame
        else {
            return
        }
        self.relayout()
    }
    
    func adjustCenter(of pageView: UIView, with scrollView: UIScrollView) {
        let minimumY = scrollView.frame.height / 2
        let minimumX = scrollView.frame.width / 2
        var y = scrollView.contentSize.height / 2
        var x = scrollView.contentSize.width / 2
        y = y < minimumY ? minimumY : y
        x = x < minimumX ? minimumX : x
        pageView.center = CGPoint(x: x, y: y)
    }
    
    func fitSize(for page: CGPDFPage) -> CGSize {
        let pageSize = page.getBoxRect(.cropBox).size
        let pageRatio = pageSize.width / pageSize.height
        let viewSize = self.scrollView.frame.size
        let viewRatio = viewSize.width / viewSize.height
        let isHorizontalFirst = pageRatio > viewRatio
        var result = CGSize.zero
        result.height = isHorizontalFirst ? viewSize.width / pageSize.width * pageSize.height : viewSize.height
        result.width = isHorizontalFirst ? viewSize.width : viewSize.height / pageSize.height * pageSize.width
        return result
    }
}

extension PDFZoomablePageView: UIScrollViewDelegate {
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.pageView
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        self.adjustCenter(of: self.pageView, with: scrollView)
    }
}
