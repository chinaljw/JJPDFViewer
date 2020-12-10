//
//  PDFPageLayer.swift
//  JJPDFViewer
//
//  Created by weigege on 2020/12/8.
//

import Foundation

open class PDFPageLayer: CATiledLayer {
    
    open var pdfBackgroundColor: UIColor = .white {
        didSet {
            self.redraw()
        }
    }
    
    open var page: CGPDFPage? {
        didSet {
            self.redraw()
        }
    }
    
    public override init(layer: Any) {
        super.init(layer: layer)
        self.setup()
    }
    
    public override init() {
        super.init()
        self.setup()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    public override func draw(in ctx: CGContext) {
        guard let page = self.page else {
            ctx.clear(self.bounds)
            return
        }
        self.tileSize = .init(width: self.bounds.width * 3, height: self.bounds.height * 3)
        ctx.setFillColor(self.pdfBackgroundColor.cgColor)
        ctx.fill(ctx.boundingBoxOfClipPath)
        ctx.translateBy(x: 0.0, y: self.bounds.height)
        ctx.scaleBy(x: 1.0, y: -1.0)
        let transform = page.getDrawingTransform(.cropBox, rect: self.bounds, rotate: 0, preserveAspectRatio: true)
//        print("draw - frame: \(self.frame), bounds: \(self.bounds), tileSize: \(self.tileSize), transform: \(transform)")
        ctx.concatenate(transform)
        ctx.drawPDFPage(page)
    }
}

public extension PDFPageLayer {
    
    func redraw() {
        self.clear()
        self.setNeedsDisplay()
    }
    
    func clear() {
        self.contents = nil
    }
}

private extension PDFPageLayer {
    
    func setup() {
        self.levelsOfDetail = 4
        self.levelsOfDetailBias = 4
    }
}
