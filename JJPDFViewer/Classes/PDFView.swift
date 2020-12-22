//
//  PDFView.swift
//  JJPDFViewer
//
//  Created by weigege on 2020/12/8.
//

import UIKit

public protocol PDFViewDelegate: NSObjectProtocol {
    
    func pdfView(_ view: PDFView, didChangePageIndex index: Int)
}

open class PDFView: UIView, PDFPageConfig {
    
    public enum ScrollDirection {
        
        case horizontal
        case vertical
        
        var direction: UICollectionView.ScrollDirection {
            switch self {
            case .horizontal:
                return .horizontal
            case .vertical:
                return .vertical
            }
        }
        
        var position: UICollectionView.ScrollPosition {
            switch self {
            case .horizontal:
                return .left
            case .vertical:
                return .top
            }
        }
    }
    
    public var document: PDFDocument? {
        didSet {
            guard self.document != oldValue else {
                return
            }
            if let document = self.document?.raw {
                self.loader = .init(document: document, preloadNumber: self.preloadNumber)
                self.loader?.pdfViewSize = self.bounds.size
            } else {
                self.loader = nil
            }
            self.reload()
        }
    }
    public var scrollDirection: ScrollDirection = .horizontal {
        didSet {
            let layout = (self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout)
            layout?.scrollDirection = self.scrollDirection.direction
            layout?.invalidateLayout()
        }
    }
    public weak var delegate: PDFViewDelegate?
    public var showsScrollIndicator: Bool = false {
        didSet {
            self.updateScrollIndicatorSetting()
        }
    }
    public var preloadNumber: UInt = PDFPageFirstFrameLoader.defaultPreloadNumber {
        didSet {
            self.loader?.preloadNumber = self.preloadNumber
        }
    }
    
    public var maximumZoomScale: CGFloat = 4.0
    public var doubleTapToZoom: Bool = true
    public var pageBackgroundColor: UIColor = .white {
        didSet {
            self.collectionView.backgroundColor = self.pageBackgroundColor
        }
    }
    public var showsPageViewScrollIndicator: Bool = true
    
    public private(set) var currentPageIndex: Int = 0 {
        didSet {
            if self.currentPageIndex != oldValue {
                self.delegate?.pdfView(self, didChangePageIndex: self.currentPageIndex)
            }
        }
    }
    
    private let collectionView: UICollectionView = .init(frame: .zero,
                                                         collectionViewLayout: UICollectionViewFlowLayout())
    
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
            if self.collectionView.isDragging {
                self.isChangingBounceInDragging = true
            }
            self.handleSizeChanging()
        }
    }
    
    // MARK: -
    var loader: PDFPageFirstFrameLoader?
    
    private var isChangingBounceInDragging: Bool = false
}

public extension PDFView {
    
    func reload() {
        self.collectionView.reloadData()
        if self.document?.numberOfPages ?? 0 > 0 {
            if self.currentPageIndex == 1 {
                self.delegate?.pdfView(self, didChangePageIndex: 1)
            }
            self.scrollToPageAt(index: 1)
        } else {
            self.currentPageIndex = 0
        }
    }
    
    func scrollToPageAt(index: Int, animated: Bool = false) {
        assert(index > 0, "Invalid index '\(index)'. Index must greater than 0.")
        self.collectionView.scrollToItem(at: .init(row: index - 1, section: 0), at: self.scrollDirection.position, animated: animated)
        if !animated {
            self.currentPageIndex = index
        }
    }
}

// MARK: - Delegates
extension PDFView: UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.document?.numberOfPages ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: PDFPageCell.identifier, for: indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let pageIndex = indexPath.row + 1
        if let cell = cell as? PDFPageCell {
            cell.pageView.fill(with: self)
            let page = self.document?.page(of: pageIndex)
            cell.refresh(with: page)
            self.loadFirstFrame(of: page, for: cell)
        }
        // preload
        self.loader?.preload(for: pageIndex)
    }
    
}

extension PDFView: UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, targetContentOffsetForProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        return self.expectedCurrentPageOffset
    }
}

extension PDFView: UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
}

extension PDFView {

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.updateCurrentPageIndex()
        // 解决快速滑动时转屏的contentOffset问题
        if scrollView.contentOffset != self.expectedCurrentPageOffset {
            self.collectionView.setContentOffset(self.expectedCurrentPageOffset, animated: true)
        }
        print("scrollViewDidEndDecelerating")
//        self.loadCurrentPDFPage()
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.updateCurrentPageIndex()
        print("scrollViewDidEndScrollingAnimation")
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isDragging && !self.isChangingBounceInDragging {
            self.updateCurrentPageIndex()
        }
        if !scrollView.isDragging {
            print("scrollViewDidScroll")
        }
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.isChangingBounceInDragging = false
        print("scrollViewDidEndDragging")
    }
}

// MARK: - Private
private extension PDFView {
    
    func setup() {
        self.collectionView.backgroundColor = self.pageBackgroundColor
        self.collectionView.register(PDFPageCell.classForCoder(), forCellWithReuseIdentifier: PDFPageCell.identifier)
        let flowLayout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        flowLayout?.scrollDirection = self.scrollDirection.direction
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.isPagingEnabled = true
        self.updateScrollIndicatorSetting()
        self.addSubview(self.collectionView)
        self.relayout()
    }
    
    func relayout() {
        // Invalidate first
//        self.collectionView.collectionViewLayout.invalidateLayout()
        self.collectionView.reloadData()
        self.collectionView.frame = self.bounds
    }
    
    func updateCurrentPageIndex() {
        let unit: CGFloat
        let offset: CGFloat
        switch self.scrollDirection {
        case .horizontal:
            unit = self.collectionView.frame.width
            offset = self.collectionView.contentOffset.x
        case .vertical:
            unit = self.collectionView.frame.height
            offset = self.collectionView.contentOffset.y
        }
        self.currentPageIndex = Int(round(offset / unit)) + 1
    }
    
    func updateScrollIndicatorSetting() {
        self.collectionView.showsHorizontalScrollIndicator = self.showsScrollIndicator
        self.collectionView.showsVerticalScrollIndicator = self.showsScrollIndicator
    }
    
    func handleSizeChanging() {
        self.loader?.pdfViewSize = self.bounds.size
        self.relayout()
    }
    
    func loadFirstFrame(of page: CGPDFPage?, for cell: PDFPageCell) {
        guard let page = page else {
            return
        }
        self.loader?.load(page: page, completion: { [weak cell] (page, image) in
            guard let cell = cell, cell.pageView.page == page else {
                return
            }
            cell.pageView.setFirstFrame(image)
        })
    }
    
    var expectedCurrentPageOffset: CGPoint {
        let collectionView = self.collectionView
        let isHorizontal = self.scrollDirection == .horizontal
        let offsetIndex = CGFloat(self.currentPageIndex - 1)
        let x = isHorizontal ? offsetIndex * collectionView.bounds.width : 0.0
        let y = isHorizontal ? 0.0 : offsetIndex * collectionView.bounds.height
        return .init(x: x, y: y)
    }
    
    func loadCurrentPDFPage() {
        if let cell = self.collectionView.cellForItem(at: .init(row: self.currentPageIndex - 1, section: 0)) as? PDFPageCell {
            cell.pageView.pageView.isHidden = false
        }
    }
}
