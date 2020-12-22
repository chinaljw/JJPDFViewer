//
//  ViewController.swift
//  JJPDFViewer
//
//  Created by chinaljw on 12/08/2020.
//  Copyright (c) 2020 chinaljw. All rights reserved.
//

import UIKit
import JJPDFViewer

class ViewController: UIViewController {

    @IBOutlet weak var pdfView: PDFView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.loadPage()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func didClickReloadItem(_ sender: Any) {
        self.pdfView.document = self.document(with: "mongodb")
//        self.pdfView.scrollToPageAt(index: 1, animated: true)
    }
}

extension ViewController {
    
    func loadPage() {
//        self.pdfView.scrollDirection = .vertical
//        self.pdfView.doubleTapToZoom = false
        self.pdfView.maximumZoomScale = 100
        self.pdfView.delegate = self
        self.pdfView.document = self.document(with: "large")
    }
    
    func document(with name: String) -> PDFDocument? {
        guard let path = name.pdfPathInMainBundle else {
            return nil
        }
        let url = URL(fileURLWithPath: path)
        return PDFDocument(fileURL: url)
    }
}

extension ViewController: PDFViewDelegate {
    
    func pdfView(_ view: PDFView, didChangePageIndex index: Int) {
        print("didChangePageIndex - index: \(index)")
    }
}

extension String {
    
    var pdfPathInMainBundle: String? {
        return Bundle.main.path(forResource: self, ofType: "pdf")
    }
}
