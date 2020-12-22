//
//  PDFViewControllerDemo.swift
//  JJPDFViewer_Example
//
//  Created by weigege on 2020/12/12.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import JJPDFViewer

class PDFViewControllerDemo: UITableViewController {

    let localPDFName = "large"
    let urlString = ""
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
            // local
        case 0:
            guard let path = localPDFName.pdfPathInMainBundle else {
                return
            }
            let vc = PDFSimpleViewController(filePath: path)
            self.navigationController?.pushViewController(vc, animated: true)
            // remote
        case 1:
            let vc = PDFSimpleViewController(urlString: urlString)
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
}
