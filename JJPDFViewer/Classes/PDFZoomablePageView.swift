//
//  PDFZoomablePageView.swift
//  JJPDFViewer
//
//  Created by weigege on 2020/12/8.
//

import UIKit

open class PDFZoomablePageView: UIView, PDFPageConfig {
    
    private static let uninitialFrame: CGRect = .zero
    
    public let scrollView: UIScrollView = .init(frame: .zero)
    public var pageView: PDFPageView = .init(frame: uninitialFrame)
    public var doubleTapToZoom: Bool = true {
        didSet {
            guard oldValue != self.doubleTapToZoom else {
                return
            }
            self.updateZoomGesture()
        }
    }
    public var maximumZoomScale: CGFloat = 4.0 {
        didSet {
            guard oldValue != self.maximumZoomScale else {
                return
            }
            self.updateMaximumZoomScale()
        }
    }
    public var pageBackgroundColor: UIColor = .white {
        didSet {
            self.updatePageBackgroundColor()
        }
    }
    public var showsPageViewScrollIndicator: Bool = true {
        didSet {
            self.updateScrollIndicator()
        }
    }
    
    public private(set) var page: CGPDFPage? {
        set {
            self.pageView.page = newValue
        }
        get {
            return self.pageView.page
        }
    }
    
    private var zoomGesture: UITapGestureRecognizer?
    private var zoomPoint: CGPoint?
    
    let firstFrameView: UIImageView = .init(frame: .zero)
    
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
    
    open override var bounds: CGRect {
        didSet {
            guard self.bounds.size != oldValue.size else {
                return
            }
            self.relayoutIfNeeded()
        }
    }
    
    public func setFirstFrame(_ image: UIImage?) {
        self.firstFrameView.image = image
    }
    
    public func refresh(with page: CGPDFPage?, firstFrameLoader: PDFPageFirstFrameLoader?) {
        self.setFirstFrame(nil)
        self.setPageView(isHidden: firstFrameLoader != nil)
        self.page = page
        self.relayout()
        self.loadFirstFrameIfNeeded(with: page, loader: firstFrameLoader)
    }
}

// MARK: - Private
private extension PDFZoomablePageView {
    
    func setup() {
        self.updatePageBackgroundColor()
        self.updateZoomGesture()
        self.updateMaximumZoomScale()
        self.updateScrollIndicator()
        self.firstFrameView.isUserInteractionEnabled = true
        self.scrollView.addSubview(self.firstFrameView)
        self.scrollView.backgroundColor = nil
        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.delegate = self
        self.pageView.isUserInteractionEnabled = false
        self.scrollView.addSubview(self.pageView)
        self.addSubview(self.scrollView)
        self.relayoutIfNeeded()
        self.setPageView(isHidden: true)
    }
    
    func relayout() {
        self.scrollView.frame = self.bounds
        self.scrollView.zoomScale = 1.0
        if let page = self.page {
            let fitSize = self.fitSize(for: page)
            self.pageView.frame.size = self.fitSize(for: page)
            self.pageView.center = self.scrollView.center
            self.firstFrameView.frame = self.pageView.frame
            self.scrollView.contentSize = fitSize
        } else {
            self.pageView.frame = Self.uninitialFrame
            self.firstFrameView.frame = self.pageView.frame
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
        return page.fitSize(with: self.scrollView.bounds.size)
    }
    
    func scroll(_ point: CGPoint, toCenterOf scrollView: UIScrollView) {
        let contentSize = scrollView.contentSize
        let viewSize = scrollView.frame.size
        var x = (point.x * contentSize.width - viewSize.width / 2)
        let maximumX = contentSize.width - viewSize.width
        x = x < maximumX ? x : maximumX
        x = x > 0.0 ? x : 0.0
        var y = (point.y * contentSize.height - viewSize.height / 2)
        let maximumY = contentSize.height - viewSize.height
        y = y < maximumY ? y : maximumY
        y = y > 0.0 ? y : 0.0
        self.scrollView.contentOffset = .init(x: x, y: y)
    }
}

// MARK: - Zoom Gesture
private extension PDFZoomablePageView {
    
    func addZoomGesture() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapToZoom(gesture:)))
        gesture.numberOfTapsRequired = 2
        gesture.numberOfTouchesRequired = 1
        self.firstFrameView.addGestureRecognizer(gesture)
        self.zoomGesture = gesture
    }
    
    func removeZoomGesture() {
        guard let gesture = self.zoomGesture else {
            return
        }
        self.pageView.removeGestureRecognizer(gesture)
    }
    
    @objc func didTapToZoom(gesture: UIGestureRecognizer) {
        let scale = self.scrollView.zoomScale <= self.maximumZoomScale / 2.0 ? self.maximumZoomScale : 1.0
        if let view = gesture.view {
            let point = gesture.location(in: view)
            let size = view.bounds.size
            self.zoomPoint = CGPoint(x: point.x / size.width, y: point.y / size.height)
        }
        self.scrollView.setZoomScale(scale, animated: true)
    }
    
    func updateZoomGesture() {
        if self.doubleTapToZoom {
            self.addZoomGesture()
        } else {
            self.removeZoomGesture()
        }
    }
    
    func updatePageBackgroundColor() {
        self.backgroundColor = self.pageBackgroundColor
    }
    
    func updateMaximumZoomScale() {
        self.scrollView.maximumZoomScale = self.maximumZoomScale
        self.pageView.pageLayer.maximumZoomScale = self.maximumZoomScale
    }
    
    func updateScrollIndicator() {
        self.scrollView.showsHorizontalScrollIndicator = self.showsPageViewScrollIndicator
        self.scrollView.showsVerticalScrollIndicator = self.showsPageViewScrollIndicator
    }
    
    func setPageView(isHidden: Bool) {
        self.pageView.isHidden = isHidden
    }
    
    func loadFirstFrameIfNeeded(with page: CGPDFPage?, loader: PDFPageFirstFrameLoader?) {
        guard let page = page, let loader = loader else { return }
        loader.load(page: page) { (page, image) in
            guard self.page == page else {
                return
            }
            self.setFirstFrame(image)
        }
    }
}

// MARK: - UIScrollViewDelegate
extension PDFZoomablePageView: UIScrollViewDelegate {
    
    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        self.setPageView(isHidden: false)
    }
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.pageView
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        self.adjustCenter(of: self.pageView, with: scrollView)
        if let zoomPoint = self.zoomPoint {
            self.scroll(zoomPoint, toCenterOf: scrollView)
        }
        self.firstFrameView.center = self.pageView.center
        self.firstFrameView.transform = .init(scaleX: scrollView.zoomScale, y: scrollView.zoomScale)
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        self.zoomPoint = nil
    }
}
