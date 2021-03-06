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
    public static var preloadNumber: UInt = 1
    
    struct Image {
        
        let raw: UIImage
        let pdfViewSize: CGSize
    }
    
    class Cache<Key: Hashable, Value> {
        
        let raw: YYMemoryCache = .init()
        
        var countLimit: UInt {
            set {
                self.raw.countLimit = newValue
            }
            get {
                return self.raw.countLimit
            }
        }
        
        func object(forKey key: Key) -> Value? {
            return self.raw.object(forKey: key) as? Value
        }
        
        func setObject(_ object: Value, forKey key: Key) {
            self.raw.setObject(object, forKey: key)
        }
    }
    /// No clear cache for now.
    public var pdfViewSize: CGSize = .zero
    /// Default is 'defaultPreloadNumber'. '0' means no-preloading.
    public var preloadNumber: UInt {
        didSet {
            self.updateCountLimit()
        }
    }
    /// Default is 'false'.
    public var shouldClearCacheWhenEnteringBackground: Bool = false {
        didSet {
            self.updateCachePolicy()
        }
    }
    
    let semaphoreLock: NSLock = .init()
    let cache: Cache<String, Image> = .init()
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
         preloadNumber: UInt = PDFPageFirstFrameLoader.preloadNumber) {
        self.document = document
        self.preloadNumber = preloadNumber
        super.init()
        self.updateCountLimit()
        self.updateCachePolicy()
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
        let pdfViewSize = self.pdfViewSize
        guard pdfViewSize != .zero else {
            completion?(page, nil)
            return
        }
        let oldCache = self.cache(of: page)
        // 因为cell will display时会把firstFrameImageView的image设置为nil，
        // 所以这里只要取到cache就回调，保证画面不会空白
        if let cache = oldCache {
            completion?(page, cache.raw)
        }
        if oldCache == nil || oldCache?.pdfViewSize != pdfViewSize {
            DispatchQueue.global().async {
                let semaphore = self.semaphore(of: page)
                semaphore.wait()
                var result: UIImage?
                if
                    let cache = self.cache(of: page),
                    cache.pdfViewSize == pdfViewSize
                {
                    result = cache.raw
                } else {
                    if let image = self.makeFirstFrame(of: page) {
                        self.set(cache: .init(raw: image, pdfViewSize: pdfViewSize),
                                 of: page)
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
    
    func key(of page: CGPDFPage) -> String {
        return "\(Unmanaged.passUnretained(page).toOpaque())"
    }
    
    func cache(of page: CGPDFPage) -> Image? {
        return self.cache.object(forKey: self.key(of: page))
    }
    
    func set(cache image: Image, of page: CGPDFPage) {
        self.cache.setObject(image, forKey: self.key(of: page))
    }
    
    func semaphore(of page: CGPDFPage) -> DispatchSemaphore {
        let key = self.key(of: page)
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
        let size = page.fitSize(with: self.pdfViewSize)
        let scale: CGFloat = UIScreen.main.scale // / 2.0
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
    
    func updateCachePolicy() {
        self.cache.raw.shouldRemoveAllObjectsWhenEnteringBackground = self.shouldClearCacheWhenEnteringBackground
    }
}
