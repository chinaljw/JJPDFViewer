//
//  DefaultPDFDocumentLoader.swift
//  JJPDFViewer
//
//  Created by weigege on 2020/12/11.
//

import Foundation
import CommonCrypto

public extension PDFSimpleViewController {
    
    class Loader: NSObject, PDFDocumentLoader {
        
        struct DownloadInfo: PDFFileInfo {
            
            var downloaded: Int64
            var fileSize: Int64
        }
        
        struct SimpleError: LocalizedError {
            
            var errorDescription: String?
            
            init(_ description: String) {
                self.errorDescription = description
            }
        }
        
        enum LoadingError: LocalizedError {
            
            case emptyURL
            case documentError
            case downloadError(_ error: Error?)
            
            var errorDescription: String? {
                switch self {
                case .emptyURL:
                    return "URL is nil."
                case .documentError:
                    return "Create 'PDFDocument' failed."
                case .downloadError(let error):
                    return "Download pdf failed. Suberror: \(error?.localizedDescription ?? "nil")."
                }
            }
        }
        
        public let url: URL?
        
        private var _session: URLSession?
        private var session: URLSession { _session! }
        private var task: URLSessionDownloadTask?
        
        public init(url: URL?) {
            self.url = url
            super.init()
            self._session = .init(configuration: .default, delegate: self, delegateQueue: .main)
            self.session.sessionDescription = "com.weigege.PDFDownloadSession"
        }
        
        convenience init(filePath: String) {
            self.init(url: URL(fileURLWithPath: filePath))
        }
        
        convenience init(urlString: String) {
            self.init(url: URL(string: urlString))
        }
        
        public weak var delegate: PDFDocumentLoaderDelegate?
        
        public func startLoading() {
            guard var url = self.url else {
                self.delegate?.loader(self, didChangeState: .completed, result: .failure(LoadingError.emptyURL))
                return
            }
            if !url.isFileURL && self.isPDFDownloaded(with: url) {
                url = self.cacheURL(of: url)
            }
            if url.isFileURL {
                if let document = PDFDocument(fileURL: url) {
                    self.delegate?.loader(self, didChangeState: .completed, result: .success(document))
                } else {
                    self.delegate?.loader(self, didChangeState: .completed, result: .failure(LoadingError.documentError))
                }
            } else {
                let task = self.session.downloadTask(with: url)
                self.task = task
                task.resume()
            }
        }
        
        public static func clearCache() throws {
            try FileManager.default.removeItem(atPath: self.cacheFolder)
        }
        
        deinit {
            self.task?.cancel()
        }
    }
}

// MARK: - SessionDelegate
extension PDFSimpleViewController.Loader: URLSessionDownloadDelegate {

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Float(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite))
        self.delegate?.loader(self,
                              didUpdateProgress: progress,
                              fileInfo: DownloadInfo(downloaded: totalBytesWritten,
                                                     fileSize: totalBytesExpectedToWrite))
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            guard let url = downloadTask.currentRequest?.url else {
                throw SimpleError("'url; is nil")
            }
            let cacheURL = self.cacheURL(of: url)
            try self.createFoldIfNeeded()
            try FileManager.default.moveItem(at: location, to: cacheURL)
            guard let document = PDFDocument(fileURL: cacheURL) else {
                throw LoadingError.documentError
            }
            self.delegate?.loader(self, didChangeState: .completed, result: .success(document))
        } catch {
            self.delegate?.loader(self, didChangeState: .completed, result: .failure(LoadingError.downloadError(error)))
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            self.delegate?.loader(self,
            didChangeState: .completed,
            result: .failure(LoadingError.downloadError(error)))
        }
    }
}

// MARK: - Private
private extension PDFSimpleViewController.Loader {
    
    func isPDFDownloaded(with url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: self.cacheURL(of: url).path)
    }
    
    func cacheURL(of url: URL) -> URL {
        let name = self.md5(with: url.absoluteString).appending(".pdf")
        let path = Self.cacheFolder.appending("/\(name)")
        return .init(fileURLWithPath: path)
    }
    
    static var cacheFolder: String {
        return NSTemporaryDirectory().appending("/com.weigege.PDFDownloader")
    }
    
    func md5(with string: String) -> String {
        let str = string.cString(using: String.Encoding.utf8)
        let strLen = CUnsignedInt(string.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
        CC_MD5(str!, strLen, result)
        let hash = NSMutableString()
        for i in 0 ..< digestLen {
            hash.appendFormat("%02x", result[i])
        }
        free(result)
        return String(format: hash as String)
    }
    
    func createFoldIfNeeded() throws {
        let folderPath = Self.cacheFolder
        guard !FileManager.default.fileExists(atPath: folderPath) else {
            return
        }
        try FileManager.default.createDirectory(atPath: Self.cacheFolder, withIntermediateDirectories: true)
    }
}

public extension PDFSimpleViewController {
    
    class LoadingView: UIView {
        
        let indicator: UIActivityIndicatorView = .init(activityIndicatorStyle: .gray)
        let failureLabel: UILabel = .init(frame: .zero)
        
        public override var bounds: CGRect {
            didSet {
                self.relayout()
            }
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            self.setup()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            self.setup()
        }
        
        public override func layoutSubviews() {
            super.layoutSubviews()
            self.relayout()
        }
    }
}

extension PDFSimpleViewController.LoadingView: PDFDocumentLoadingView {
    
    public func refresh(with state: PDFDocumentLoadingState, result: PDFDocumentLoadingResult?) {
        switch state {
        case .loading:
            self.failureLabel.isHidden = true
            self.indicator.isHidden = false
        case .completed:
            if case .failure = result {
                self.failureLabel.isHidden = false
                self.indicator.isHidden = true
            }
        default:
            break
        }
    }
    
    public func update(progres: Float, fileInfo: PDFFileInfo) {
        
    }
}

private extension PDFSimpleViewController.LoadingView {
    
    func setup() {
        self.addSubview(self.indicator)
        self.indicator.startAnimating()
        self.failureLabel.textAlignment = .center
        self.failureLabel.textColor = .lightGray
        self.failureLabel.text = NSLocalizedString("加载失败", comment: "")
        self.failureLabel.isHidden = true
        self.addSubview(self.failureLabel)
        self.relayout()
    }
    
    func relayout() {
        self.indicator.center = .init(x: self.bounds.midX, y: self.bounds.midY)
        self.failureLabel.frame.size = self.failureLabel.intrinsicContentSize
        self.failureLabel.center = self.indicator.center
    }
}
