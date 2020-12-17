//
//  PDFPageView.swift
//  JJPDFViewer
//
//  Created by weigege on 2020/12/8.
//

import UIKit

open class PDFPageView: UIView {
    
    var imageLayer: ImageLayer = .init()
    public var pageLayer: PDFPageLayer = .init()

    open var page: CGPDFPage? {
        didSet {
            guard self.page != oldValue else {
                return
            }
//            if self.pageLayer.superlayer != nil {
//                self.pageLayer.removeFromSuperlayer()
//                self.pageLayer = .init()
//                self.pageLayer.frame = self.bounds
//                self.layer.addSublayer(self.pageLayer)
//            }
            self.pageLayer.page = self.page
//            self.layer.setNeedsDisplay()
//            self.imageLayer.removeFromSuperlayer()
//            self.imageLayer = .init()
//            self.layer.insertSublayer(self.imageLayer, below: self.pageLayer)
//            self.imageLayer.frame = self.bounds
//            self.imageLayer.page = self.page
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.relayout()
//        self.pageLayer.redraw()
    }
    
    open override var frame: CGRect {
        didSet {
            self.relayout()
            self.pageLayer.redraw()
        }
    }
    
//    open override class var layerClass: AnyClass {
//        return PDFPageLayer.classForCoder()
//    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
//        self.layer.addSublayer(self.imageLayer)
        self.layer.addSublayer(self.pageLayer)
        self.relayout()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public extension PDFPageView {
    
//    var pageLayer: PDFPageLayer {
//        return self.layer as! PDFPageLayer
//    }
}

extension PDFPageView {
    
    func relayout() {
//        self.imageLayer.frame = self.bounds
        self.pageLayer.frame = self.bounds
    }
    
    class PreviewView: UIView {
        
        var page: CGPDFPage? {
            set {
                self.isUserInteractionEnabled = false
                self.imageLayer.page = newValue
            }
            get {
                return self.imageLayer.page
            }
        }
        
        override class var layerClass: AnyClass {
            return ImageLayer.self
        }
        
        var imageLayer: ImageLayer {
            return self.layer as! ImageLayer
        }
        
        override var bounds: CGRect {
            didSet {
                guard self.bounds.size != oldValue.size else {
                    return
                }
                self.setNeedsDisplay()
            }
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            self.setNeedsDisplay()
        }
    }
    
    class ImageLayer: CALayer {
        
        static var cache: NSCache<NSString, UIImage> = .init()
        
        static var loader: PDFPagePreviewLoader?
        
//        var image: UIImage? {
//            guard let page = self.page else {
//                return nil
//            }
//            print("key: \(self.key(for: page))")
//            Self.cache.countLimit = 10
//            return Self.cache.object(forKey: self.key(for: page) as NSString)
//        }
        
        var image: UIImage?
        
        override var bounds: CGRect {
            didSet {
                guard bounds.size != oldValue.size else {
                    return
                }
                self.setNeedsDisplay()
            }
        }
        
        var page: CGPDFPage? {
            didSet {
//                self.setNeedsDisplay()
//                self.testDraw()
//                self.drawsAsynchronously = true
                if Self.loader == nil, let document = page?.document {
                    Self.loader = .init(document: document)
                    Self.loader?.preload(with: self.bounds.size)
                }
                self.image = nil
                guard let page = self.page else {
                    return
                }
//                guard  self.page != oldValue || self.image == nil else {
//                    return
//                }
                self.contentsScale = UIScreen.main.scale
                self.contents = nil
//                guard self.page != oldValue else {
//                    return
//                }
//
                Self.loader?.load(page: page, with: self.bounds.size, completion: { [weak self] page, image in
                    print("didLoadPage - page: \(page), self.page: \(String(describing: self?.page))")
                    guard let self = self, page == self.page else { return }
                    self.image = image
                    self.setNeedsDisplay()
                })
                return
                let cache = Self.cache
                let key = self.key(for: page)
//                self.contents = nil
                if cache.object(forKey: key as NSString) != nil {
                    self.setNeedsDisplay()
                } else {
                    DispatchQueue.global().async { [weak self] in
                        guard let self = self, let image = self.makeImage(with: page) else {
                            return
                        }
                        cache.setObject(image, forKey: key as NSString)
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            if let page = self.page, key == self.key(for: page) {
                                self.setNeedsDisplay()
                            }
                        }
                    }
                }
//                self.setNeedsDisplay()
            }
        }
        
        func key(for page: CGPDFPage) -> String {
            return "\(Unmanaged.passRetained(page).toOpaque())"
        }
        
        override func draw(in ctx: CGContext) {
//            return
            guard let page = self.page else {
                ctx.clear(self.bounds)
                return
            }
            ctx.setFillColor(UIColor.clear.cgColor)
            ctx.fill(ctx.boundingBoxOfClipPath)
            ctx.translateBy(x: 0.0, y: self.bounds.height)
            ctx.scaleBy(x: 1.0, y: -1.0)
            if let image = self.image?.cgImage {
                ctx.draw(image, in: self.bounds)
            } else {
                return
//            print("draw in - layer: \(Unmanaged.passUnretained(self).toOpaque())")

            var halfBounds = self.bounds
//            halfBounds.size.width /= 10.0
//            halfBounds.size.height /= 10.0
            let transform = page.getDrawingTransform(.cropBox, rect: halfBounds, rotate: 0, preserveAspectRatio: true)
//            print("draw - frame: \(self.frame), bounds: \(self.bounds), tileSize: \(self.tileSize), transform: \(transform)")
            ctx.concatenate(transform)
//            let pdfSize = page.getBoxRect(.cropBox).size
//            ctx.scaleBy(x: halfBounds.size.width / pdfSize.width, y: halfBounds.height / pdfSize.height)
            ctx.drawPDFPage(page)
            if let cg = ctx.makeImage() {
//                self.image = UIImage(cgImage: cg)
            }

//            ctx.scaleBy(x: 2.0, y: 2.0)
//            UIGraphicsGetImageFromCurrentImageContext()
            }
        }
        
        func makeImage(with page: CGPDFPage?) -> UIImage? {
            guard let pdfPage = page else {
                return nil
            }
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue
            var mediaBoxRect = pdfPage.getBoxRect(.cropBox)
            let scale: CGFloat = UIScreen.main.scale // / 2.0
//            let width = Int(mediaBoxRect.width * scale)
//            let height = Int(mediaBoxRect.height * scale)
            let width = Int(mediaBoxRect.width * scale)
            let height = Int(mediaBoxRect.height * scale)

//            let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo)!
//            context.interpolationQuality = .high
//            context.setFillColor(UIColor.white.cgColor)
//            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
////            context.scaleBy(x: scale, y: scale)
//            let rect = CGRect(x: 0.0, y: 0.0, width: CGFloat(width), height: CGFloat(height))
//            let transform = pdfPage.getDrawingTransform(.cropBox, rect: rect, rotate: 0, preserveAspectRatio: true)
//            context.concatenate(transform)
//            context.drawPDFPage(pdfPage)
//            let context = CGContext(data: nil, width: Int(self.bounds.width), height: Int(self.bounds.height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo)!
//            let contextSize = mediaBoxRect.size
            let old = mediaBoxRect.width
            print("before mediaBoxRect: \(mediaBoxRect), box ratio: \(mediaBoxRect.width / mediaBoxRect.height), bounds: \(self.bounds), bounds ratio: \(self.bounds.width / self.bounds.height)")
            mediaBoxRect.size.width = self.bounds.width
            mediaBoxRect.size.height = mediaBoxRect.size.width * mediaBoxRect.height / old
//            mediaBoxRect.size = self.bounds.size
//            mediaBoxRect.size.height = CGFloat(ceil(Double(mediaBoxRect.height)))
            print("after mediaBoxRect: \(mediaBoxRect), box ratio: \(mediaBoxRect.width / mediaBoxRect.height), bounds: \(self.bounds), bounds ratio: \(self.bounds.width / self.bounds.height)")
            UIGraphicsBeginImageContextWithOptions(mediaBoxRect.size, false, scale)
            defer {
                UIGraphicsEndImageContext()
            }
            guard let context = UIGraphicsGetCurrentContext() else {
                return nil
            }
//            guard let context = CGContext(data: nil, width: Int(self.bounds.width), height: Int(self.bounds.height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo) else {
//                return nil
//            }
            context.setFillColor(UIColor.white.cgColor)
            context.fill(context.boundingBoxOfClipPath)
            context.translateBy(x: 0.0, y: mediaBoxRect.height)
            context.scaleBy(x: 1.0, y: -1.0)
            
            context.interpolationQuality = .high
            let transform = pdfPage.getDrawingTransform(.cropBox, rect: mediaBoxRect, rotate: 0, preserveAspectRatio: true)
            context.concatenate(transform)
//            context.scaleBy(x: scale, y: scale)
//            print("bounds: \(self.bounds), transform: \(transform)")
//            context.scaleBy(x:  self.bounds.width / mediaBoxRect.width, y: self.bounds.height / mediaBoxRect.height)
            context.drawPDFPage(pdfPage)
//            if let cgImage = context.makeImage() {
            if let cgImage = UIGraphicsGetImageFromCurrentImageContext() {
//                return UIImage(cgImage: cgImage)
                if let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
                    let filePath = path.appending("/test.png")
                    try? UIImagePNGRepresentation(cgImage)?.write(to: .init(fileURLWithPath: filePath))
                }
                return cgImage
            } else {
                return nil
            }
        }
    }
}

/*
 context.setFillColor(UIColor.white.cgColor)
 context.fill(context.boundingBoxOfClipPath)
 context.translateBy(x: 0.0, y: self.bounds.height)
 context.scaleBy(x: 1.0, y: -1.0)
 let transform = pdfPage.getDrawingTransform(.cropBox, rect: self.bounds, rotate: 0, preserveAspectRatio: true)
 context.concatenate(transform)
 context.drawPDFPage(pdfPage)
 */
