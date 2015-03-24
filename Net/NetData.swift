//
//  NetData.swift
//  Net
//
//  Created by Le Van Nghia on 8/3/14.
//  Copyright (c) 2014 Le Van Nghia. All rights reserved.
//

import Foundation
#if os(OSX)
    import AppKit
    func PNGRep(image: NSImage) -> NSData! {
        let imageRep = NSBitmapImageRep(data: image.TIFFRepresentation!)
        return imageRep?.representationUsingType(NSBitmapImageFileType.NSPNGFileType, properties: [:])
    }

    func JPEGRep(image: NSImage, compressionQuanlity: CGFloat) -> NSData! {
        let imageRep = NSBitmapImageRep(data: image.TIFFRepresentation!)
        return imageRep?.representationUsingType(NSBitmapImageFileType.NSJPEGFileType, properties: [NSImageCompressionFactor:compressionQuanlity])
    }
    #else
    import UIKit

    func PNGRep(image: UIImage) -> NSData! {
        return UIImagePNGRepresentation(image)
    }

    func JPEGRep(image: UIImage, compressionQuanlity: CGFloat) -> NSData! {
        return UIImageJPEGRepresentation(image, compressionQuanlity)
    }
#endif

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
    
    init(pngImage: AnyImage, filename: String) {
        data = PNGRep(pngImage)
        self.mimeType = MimeType.ImagePng
        self.filename = filename
    }
    
    init(jpegImage: AnyImage, compressionQuanlity: CGFloat, filename: String) {
        data = JPEGRep(jpegImage, compressionQuanlity)
        self.mimeType = MimeType.ImageJpeg
        self.filename = filename
    }
}