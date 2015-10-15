//
//  NetData.swift
//  Net
//
//  Created by Le Van Nghia on 8/3/14.
//  Copyright (c) 2014 Le Van Nghia. All rights reserved.
//

import Foundation
import UIKit

enum MimeType: String {
    case ImageJpeg = "image/jpeg"
    case ImagePng = "image/png"
    case ImageGif = "image/gif"
    case Json = "application/json"
    case Unknown = ""
    
    func getString() -> String? {
        switch self {
        case .ImagePng:
            fallthrough
        case .ImageJpeg:
            fallthrough
        case .ImageGif:
            fallthrough
        case .Json:
            return self.rawValue
        case .Unknown:
            fallthrough
        default:
            return nil
        }
    }
}

class NetData
{
    let data: NSData
    let mimeType: MimeType
    let filename: String
    
    init(data: NSData, mimeType: MimeType, filename: String) {
        self.data = data
        self.mimeType = mimeType
        self.filename = filename
    }
    
    init(pngImage: UIImage, filename: String) {
        data = UIImagePNGRepresentation(pngImage)!
        self.mimeType = MimeType.ImagePng
        self.filename = filename
    }
    
    init(jpegImage: UIImage, compressionQuanlity: CGFloat, filename: String) {
        data = UIImageJPEGRepresentation(jpegImage, compressionQuanlity)!
        self.mimeType = MimeType.ImageJpeg
        self.filename = filename
    }
}