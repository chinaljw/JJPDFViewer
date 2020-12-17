//
//  PDFDocument.swift
//  JJPDFViewer
//
//  Created by weigege on 2020/12/8.
//

import Foundation

class Cache<Key: AnyObject, Obj: UIImage>: YYMemoryCache {
    
//    func object(forKey key: Key) -> Obj? {
//        return self.object(forKey: key)
//    }
//
//    func setObject(_ object: Obj, forKey key: Key) {
//        self.setObject(object, forKey: key)
//    }
    
    override init() {
        super.init()
        self.countLimit = 5
    }
}

@objcMembers
open class PDFDocument: NSObject {
    
    public let raw: CGPDFDocument
    
    public init(_ raw: CGPDFDocument) {
        self.raw = raw
        super.init()
    }
}

// MARK: - Convenience Inits
public extension PDFDocument {
    
    convenience init?(fileURL: URL) {
        guard let document = CGPDFDocument(fileURL as CFURL) else {
            return nil
        }
        self.init(document)
    }
    
    convenience init?(pdfData: Data) {
        guard
            let provider = CGDataProvider(data: pdfData as CFData),
            let document = CGPDFDocument(provider)
        else {
            return nil
        }
        self.init(document)
    }
}

// MARK: -
public extension PDFDocument {
    
    var numberOfPages: Int {
        return self.raw.numberOfPages
    }
    
    func page(of index: Int) -> CGPDFPage? {
        return self.raw.page(at: index)
    }
}

public class PDFPagePreviewLoader: NSObject {
    
    let cacheLock: NSLock = .init()
    let semaphoreLock: NSLock = .init()
    
    var cached: Set<String> = []
    
    var caches: [String: Cache<NSString, UIImage>] {
        get {
            defer {
                self.cacheLock.unlock()
            }
            self.cacheLock.lock()
            print("number of object: \(self._caches.values.first?.countLimit)")
            return self._caches
        }
        set {
            defer {
                self.cacheLock.unlock()
            }
            self.cacheLock.lock()
            self._caches = newValue
        }
    }
    var _caches: [String: Cache<NSString, UIImage>] = [:]
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
    
    let preloadNumber: Int
    let document: CGPDFDocument
    
    init(document: CGPDFDocument, preloadNumber: Int = 4) {
        self.document = document
        self.preloadNumber = preloadNumber
    }
    
    func preload(with size: CGSize) {
        let cache = Cache<NSString, UIImage>()
//        cache.delegate = self
//        cache.countLimit = self.preloadNumber
        self.caches[self.key(of: size)] = cache
        for i in 1...document.numberOfPages {
            guard i <= self.preloadNumber else {
                return
            }
            guard let page = document.page(at: i) else {
                return
            }
            self.load(page: page, with: size)
        }
    }
    
    func load(page: CGPDFPage, with size: CGSize, completion: ((CGPDFPage, UIImage?) -> Void)? = nil) {
//        completion?(page, nil)
//        return
        print("load page - page: \(page), size: \(size)")
        if let cache = self.cache(of: page, with: size) {
            completion?(page, cache)
        } else {
            DispatchQueue.global().async {
                let semaphore = self.semaphore(of: page)
                semaphore.wait()
                var result: UIImage?
                if let cache = self.cache(of: page, with: size) {
                    result = cache
                } else {
                    print("make page begin - page: \(page)")
                    if let image = self.makeImage(with: page, size: size) {
                        self.set(cache: image, of: page, with: size)
                        result = image
                        print("make page succeeded - page: \(page)")
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
    
    func cache(of page: CGPDFPage, with size: CGSize) -> UIImage? {
        print("cache - page: \(page)")
        print("cache - cache: \(self.caches[self.key(of: size)])")
        return self.caches[self.key(of: size)]?.object(forKey: self.key(of: page)) as? UIImage
    }
    
    func set(cache image: UIImage, of page: CGPDFPage, with size: CGSize) {
//        self.cached.insert(self.key(of: image))
//        print("== cache image - page: \(page) image: \(image), cached: \(self.cached)")
        self.caches[self.key(of: size)]?.setObject(image, forKey: self.key(of: page))
    }
    
    deinit {
        print("deinit \(self)")
    }
    
    func semaphore(of page: CGPDFPage) -> DispatchSemaphore {
        let key = self.key(of: page) as String
        print("semaphores - self: \(self), key: \(key)")
        print("semaphores - semaphores: \(self.semaphores)")
        if let semaphore = self.semaphores[key] {
            return semaphore
        } else {
            let semaphore = DispatchSemaphore(value: 1)
            self.semaphores[key] = semaphore
            return semaphore
        }
    }
    
    func makeImage(with page: CGPDFPage, size: CGSize) -> UIImage? {
        let bounds = CGRect(origin: .zero, size: size)
        let mediaBoxRect = page.getBoxRect(.cropBox)
        let scale: CGFloat = UIScreen.main.scale // / 2.0
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

extension PDFPagePreviewLoader: NSCacheDelegate {
    
    public func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
//        print("== willEvict before - obj: \(obj), cached: \(self.cached)")
//        self.cached.remove(self.key(of: obj as! UIImage))
//        print("== willEvict after - obj: \(obj), cached: \(self.cached)")
    }
    
    func key(of image: UIImage) -> String {
        return "\(Unmanaged.passRetained(image).toOpaque())"
    }
}
