//
//  PDFPageFirstFrameLoader.swift
//  JJPDFViewer
//
//  Created by weigege on 2020/12/18.
//

import UIKit
import YYCache

public class PDFPageFirstFrameLoader: NSObject {
    
    /// Default is '1'
    public static var defaultPreloadNumber: UInt = 1
    
    class Cache<Key: AnyObject, Obj: UIImage>: YYMemoryCache {
        
    }
    /// No clear cache for now.
    public var pdfViewSize: CGSize = .zero
    /// Default is 'defaultPreloadNumber'. '0' means no-preloading.
    public var preloadNumber: UInt {
        didSet {
            self.updateCountLimit()
        }
    }
    
    let semaphoreLock: NSLock = .init()
    let cache: Cache<NSString, UIImage> = .init()
    var semaphores: [String: DispatchSemaphore] {
        get {
            defer {
                self.semaphoreLock.unlock()
            }
            self.semaphoreLock.lock()
            return self._semaphores
        }
        set {
            defer {
                self.semaphoreLock.unlock()
            }
            self.semaphoreLock.lock()
            self._semaphores = newValue
        }
    }
    var _semaphores: [String: DispatchSemaphore] = [:]
    
    public let document: CGPDFDocument
    
    init(document: CGPDFDocument,
         preloadNumber: UInt = PDFPageFirstFrameLoader.defaultPreloadNumber) {
        self.document = document
        self.preloadNumber = preloadNumber
        super.init()
        self.updateCountLimit()
    }
    
    func preload(for index: Int) {
        assert(index >= 0, "Invalid index - index: \(index)")
        for i in 1...self.preloadNumber {
            let i = Int(i)
            let next = index + i
            let last = index - i
            if let nextPage = self.document.page(at: next) {
                 self.load(page: nextPage)
            }
            if let lastPage = self.document.page(at: last) {
                self.load(page: lastPage)
            }
        }
    }
    
    func load(page: CGPDFPage, completion: ((CGPDFPage, UIImage?) -> Void)? = nil) {
        print("willLoad \(page)")
        guard self.pdfViewSize != .zero else {
            completion?(page, nil)
            return
        }
        if let cache = self.cache(of: page) {
            completion?(page, cache)
        } else {
            let pdfViewSize = self.pdfViewSize
            DispatchQueue.global().async {
                let semaphore = self.semaphore(of: page)
                semaphore.wait()
                var result: UIImage?
                if let cache = self.cache(of: page) {
                    result = cache
                } else {
                    if
                        let image = self.makeFirstFrame(of: page),
                        pdfViewSize == self.pdfViewSize
                    {
                        self.set(cache: image, of: page)
                        result = image
                    }
                }
                DispatchQueue.main.async {
                    completion?(page, result)
                    semaphore.signal()
                }
            }
        }
    }
    
    func key(of size: CGSize) -> String {
        return "\(size.width).\(size.height)"
    }
    
    func key(of page: CGPDFPage) -> NSString {
        return "\(Unmanaged.passUnretained(page).toOpaque())" as NSString
    }
    
    func cache(of page: CGPDFPage) -> UIImage? {
        return self.cache.object(forKey: self.key(of: page)) as? UIImage
    }
    
    func set(cache image: UIImage, of page: CGPDFPage) {
        self.cache.setObject(image, forKey: self.key(of: page))
    }
    
    func semaphore(of page: CGPDFPage) -> DispatchSemaphore {
        let key = self.key(of: page) as String
//        print("semaphores - self: \(self), key: \(key)")
//        print("semaphores - semaphores: \(self.semaphores)")
        if let semaphore = self.semaphores[key] {
            return semaphore
        } else {
            let semaphore = DispatchSemaphore(value: 1)
            self.semaphores[key] = semaphore
            return semaphore
        }
    }
    
    func makeFirstFrame(of page: CGPDFPage) -> UIImage? {
        guard self.pdfViewSize != .zero else {
            return nil
        }
        var size = page.fitSize(with: self.pdfViewSize)
        let scale: CGFloat = UIScreen.main.scale // / 2.0
        // Limit the size of the image to pageSize.
        let pageSize = page.getBoxRect(.cropBox)
        if size.width > pageSize.width {
            size = pageSize.size
        }
//        print("will make first frame - page: \(page), pdfViewSize: \(self.pdfViewSize), size: \(size), scale: \(scale)")
        let bounds = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer {
            UIGraphicsEndImageContext()
        }
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        context.setFillColor(UIColor.white.cgColor)
        context.fill(context.boundingBoxOfClipPath)
        context.translateBy(x: 0.0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.interpolationQuality = .high
        let transform = page.getDrawingTransform(.cropBox, rect: bounds, rotate: 0, preserveAspectRatio: true)
        context.concatenate(transform)
        context.drawPDFPage(page)
        if let cgImage = UIGraphicsGetImageFromCurrentImageContext() {
            return cgImage
        } else {
            return nil
        }
    }
}

private extension PDFPageFirstFrameLoader {
    
    func updateCountLimit() {
        // Plus 1 to make sure pages that near current page can't be evicted.
        self.cache.countLimit = 1 + 2 * (self.preloadNumber + 1)
    }
}
