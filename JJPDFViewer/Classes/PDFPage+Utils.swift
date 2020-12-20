//
//  PDFPage+Utils.swift
//  JJPDFViewer
//
//  Created by weigege on 2020/12/18.
//

import Foundation

extension CGPDFPage {
    
    func fitSize(with viewSize: CGSize, box: CGPDFBox = .cropBox) -> CGSize {
        let pageSize = self.getBoxRect(box).size
        let pageRatio = pageSize.width / pageSize.height
        let viewRatio = viewSize.width / viewSize.height
        let isHorizontalFirst = pageRatio > viewRatio
        var result = CGSize.zero
        result.height = isHorizontalFirst ? viewSize.width / pageSize.width * pageSize.height : viewSize.height
        result.width = isHorizontalFirst ? viewSize.width : viewSize.height / pageSize.height * pageSize.width
        return result
    }
}
