//
//  NetHelper.swift
//  example
//
//  Created by Le Van Nghia on 8/13/14.
//  Copyright (c) 2014 Le Van Nghia. All rights reserved.
//

import Foundation

class NetHelper
{
    typealias Pair = (String, AnyObject)

    /**
    *  check parameters
    *
    *  @param HttpMethod
    *
    *  @return
    */
    class func isQueryParams(method: HttpMethod) -> Bool {
        return method == HttpMethod.GET
    }
    
    /**
    *  should send with multi-part if the parameter contains complicated data like image
    *
    *  @param NSDictionary
    *
    *  @return
    */
    class func isMultiPart(params: NSDictionary) -> Bool {
        var isMultiPart = false
        for (_, value) in params {
            if value is NetData {
                isMultiPart = true
                break
            }
        }
        
        return isMultiPart
    }
    
    /**
    *  get query string with UTF8 encoded from parameters
    *
    *  @param NSDictionary!
    *
    *  @return
    */
    class func queryStringFromParams(params: NSDictionary) -> String {
        let paramsArray = self.convertParamsToArray(params)
        var queryString = join("&", paramsArray.map{"\($0)=\($1)"})
        
        return queryString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
    }
    
    /**
    *  get NSData from parameters
    *
    *  @param NSDictionary!
    *
    *  @return
    */
    class func dataFromParams(params: NSDictionary) -> NSData? {
        let query = queryStringFromParams(params)
        return query.dataUsingEncoding(NSUTF8StringEncoding)
    }
    
    /**
    *   get data for multi-part sending
    *   http://www.w3.org/TR/html401/interact/forms.html#h-17.13.4
    *
    *  @param String
    *
    *  @return
    */
    class func dataFromParamsWithBoundary(params: NSDictionary, boundary: String) -> NSData {
        var data = NSMutableData()
        
        let prefixString = "--\(boundary)\r\n"
        let prefixData = prefixString.dataUsingEncoding(NSUTF8StringEncoding)
        let seperatorString = "\r\n"
        let seperatorData = seperatorString.dataUsingEncoding(NSUTF8StringEncoding)
        let paramsArray = self.convertParamsToArray(params)
        
        for (key, value) in paramsArray {
            var valueData: NSData?
            var valueType: String?
            var filenameClause = ""
            
            if let netData = value as? NetData {
                valueData = netData.data
                valueType = netData.mimeType.getString()
                filenameClause = " filename=\"\(netData.filename)\""
            }
            else {
                let stringValue = "\(value)"
                valueData = stringValue.dataUsingEncoding(NSUTF8StringEncoding)
            }
            
            // append prefix
            data.appendData(prefixData!)
            
            // append content disposition
            let contentDispositionString = "Content-Disposition: form-data; name=\"\(key)\";\(filenameClause)\r\n"
            let contentDispositionData = contentDispositionString.dataUsingEncoding(NSUTF8StringEncoding)
            data.appendData(contentDispositionData!)
            
            // append content type
            if let type = valueType {
                let contentTypeString = "Content-Type: \(type)\r\n"
                let contentTypeData = contentTypeString.dataUsingEncoding(NSUTF8StringEncoding)
                data.appendData(contentTypeData!)
            }
            
            // append data
            data.appendData(seperatorData!)
            data.appendData(valueData!)
            data.appendData(seperatorData!)
        }
        
        // append ending data
        let endingString = "--\(boundary)--\r\n"
        let endingData = endingString.dataUsingEncoding(NSUTF8StringEncoding)
        data.appendData(endingData!)
        
        return data
    }

    private class func convertParamsToArray(params: NSDictionary) -> [Pair] {
        var result = [Pair]()
        
        for (key, value) in params {
            if let arrayValue = value as? NSArray {
                for nestedValue in arrayValue {
                    let dic = ["\(key)[]": nestedValue]
                    result += self.convertParamsToArray(dic)
                }
            }
            else if let dicValue = value as? NSDictionary {
                for (nestedKey, nestedValue) in dicValue {
                    let dic = ["\(key)[\(nestedKey)]": nestedValue]
                    result += self.convertParamsToArray(dic)
                }
            }
            else {
                result.append(("\(key)", value))
            }
        }
        
        return result
    }
}
