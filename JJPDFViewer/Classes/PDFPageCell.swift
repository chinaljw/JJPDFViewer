//
//  PDFCell.swift
//  JJPDFViewer
//
//  Created by weigege on 2020/12/8.
//

import UIKit

open class PDFPageCell: UICollectionViewCell {
    
    static let identifier = "PDFPageCell"
    
    var pageView: PDFZoomablePageView = .init(frame: .zero)
    
    open override var frame: CGRect {
        didSet {
            self.relayout()
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
        self.relayout()
    }
}

public extension PDFPageCell {
    
    func refresh(with page: CGPDFPage?, firstFrameLoader: PDFPageFirstFrameLoader?) {
        self.pageView.refresh(with: page, firstFrameLoader: firstFrameLoader)
    }
}

private extension PDFPageCell {
    
    func setup() {
        self.contentView.addSubview(self.pageView)
        self.relayout()
    }
    
    func relayout() {
        self.pageView.frame = self.bounds
    }
}
