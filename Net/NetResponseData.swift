//
//  ResponseSerialization.swift
//  Net
//
//  Created by Le Van Nghia on 7/31/14.
//  Copyright (c) 2014 Le Van Nghia. All rights reserved.
//

import Foundation
import UIKit

class ResponseData
{
    var urlResponse : NSURLResponse
    var data: NSData

    init(response: NSURLResponse, data: NSData) {
        self.urlResponse = response
        self.data = data
    }

    /**
    *  parse json with urlResponse
    *
    *  @param NSErrorPointer
    *
    *  @return json dictionary
    */
    func json() throws -> NSDictionary {
        var error: NSError! = NSError(domain: "Migrator", code: 0, userInfo: nil)
        if let httpResponse = urlResponse as? NSHTTPURLResponse {
            if httpResponse.statusCode == 200 {
                let jsonData = (try! NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)) as! NSDictionary
                return jsonData
            }
            else {
                error = NSError(domain: "HTTP_ERROR_CODE", code: httpResponse.statusCode, userInfo: nil)
            }
        }
        throw error
    }

    /**
    *  convert urlResponse to image
    *
    *  @return UIImage
    */
    func image() throws -> UIImage {
        var error: NSError! = NSError(domain: "Migrator", code: 0, userInfo: nil)
        if let httpResponse = urlResponse as? NSHTTPURLResponse {
            if httpResponse.statusCode == 200 && data.length > 0 {
                if let value = UIImage(data: data) {
                    return value
                }
                throw error
            }
            else {
                error = NSError(domain: "HTTP_ERROR_CODE", code: httpResponse.statusCode, userInfo: nil)
            }
        }
        throw error
    }

    /**
    *  parse xml
    *
    *  @param NSXMLParserDelegate
    *
    *  @return
    */
    func parseXml(delegate: NSXMLParserDelegate) throws {
        var error: NSError! = NSError(domain: "Migrator", code: 0, userInfo: nil)
        if let httpResponse = urlResponse as? NSHTTPURLResponse {
            if httpResponse.statusCode == 200 {
                let xmlParser = NSXMLParser(data: data)
                xmlParser.delegate = delegate
                xmlParser.parse()
                return
            }
            else {
                error = NSError(domain: "HTTP_ERROR_CODE", code: httpResponse.statusCode, userInfo: nil)
            }
        }
        throw error
    }
}
