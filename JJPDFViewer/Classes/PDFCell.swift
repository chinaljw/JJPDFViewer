//
//  PDFCell.swift
//  JJPDFViewer
//
//  Created by weigege on 2020/12/8.
//

import UIKit

open class PDFCell: UICollectionViewCell {
    
    static let identifier = "PDFCell"
    
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
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        self.pageView.setFirstFrame(nil)
    }
}

public extension PDFCell {
    
    func refresh(with page: CGPDFPage?) {
        self.pageView.page = page
    }
}

private extension PDFCell {
    
    func setup() {
        self.contentView.addSubview(self.pageView)
        self.relayout()
    }
    
    func relayout() {
        self.pageView.frame = self.bounds
    }
}
