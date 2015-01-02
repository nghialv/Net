//
//  NetUploadTask.swift
//  Net
//
//  Created by Le Van Nghia on 8/4/14.
//  Copyright (c) 2014 Le Van Nghia. All rights reserved.
//

import Foundation

protocol UploadTaskDelegate {
    func didCreateUploadTask(task: NSURLSessionUploadTask, uploadTask: UploadTask)
    func didRemoveUploadTask(task: NSURLSessionUploadTask)
}

class UploadTask
{
    enum State {
        case Init, Uploading, Suspending, Canceled, Completed, Failed
    }
    
    typealias ProgressHandler = (Float) -> ()
    typealias CompletionHandler = (NSError?) -> ()
    typealias SuccessHandler = (ResponseData) -> ()
    typealias FailureHandler = (NSError!) -> ()
    
    private var session: NSURLSession
    private var delegate: UploadTaskDelegate
    private var task: NSURLSessionUploadTask!
    private var request: NSMutableURLRequest
    
    private var progressHandler: ProgressHandler?
    private var successHandler: SuccessHandler?
    private var failureHandler: FailureHandler?

    
    private var state: State = .Init
   
    init(_ session: NSURLSession,_ delegate: UploadTaskDelegate,_ absoluteUrl: String,_ progressHandler: ProgressHandler?, _ successHandler: SuccessHandler? = nil, _ failureHandler: FailureHandler? = nil) {
        self.session = session
        self.delegate = delegate
        let url = NSURL(string: absoluteUrl)
        self.request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = HttpMethod.POST.rawValue
    
        self.progressHandler = progressHandler
        self.successHandler = successHandler
        self.failureHandler = failureHandler
    }
    
    convenience init(session: NSURLSession, delegate: UploadTaskDelegate, absoluteUrl: String, data: NSData, progressHandler: ProgressHandler? = nil, successHandler: SuccessHandler? = nil, failureHandler: FailureHandler? = nil) {
        self.init(session, delegate, absoluteUrl, progressHandler, successHandler, failureHandler)
        
        // TODO: config for request
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        task = session.uploadTaskWithRequest(request, fromData: data){ self.didComplete($0, $1, $2) }
        
        delegate.didCreateUploadTask(task, uploadTask: self)
    }
   
    convenience init(session: NSURLSession, delegate: UploadTaskDelegate, absoluteUrl: String, params: NSDictionary, progressHandler: ProgressHandler? = nil, successHandler: SuccessHandler? = nil, failureHandler: FailureHandler? = nil) {
        
        self.init(session, delegate, absoluteUrl, progressHandler, successHandler, failureHandler)
        
        let boundary = "NET-UPLOAD-boundary-\(arc4random())-\(arc4random())"
        let paramsData = NetHelper.dataFromParamsWithBoundary(params, boundary: boundary)
        let contentType = "multipart/form-data; boundary=\(boundary)"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("\(paramsData.length)", forHTTPHeaderField: "Content-Length")
        
        task = session.uploadTaskWithRequest(request, fromData: paramsData){ self.didComplete($0, $1, $2) }
        
        delegate.didCreateUploadTask(task, uploadTask: self)
    }
    
    convenience init(session: NSURLSession, delegate: UploadTaskDelegate, absoluteUrl: String, fromFile: NSURL, progressHandler: ProgressHandler?, successHandler: SuccessHandler? = nil, failureHandler: FailureHandler? = nil) {
        
        self.init(session, delegate, absoluteUrl, progressHandler, successHandler, failureHandler)

        task = session.uploadTaskWithRequest(request, fromFile: fromFile){ self.didComplete($0, $1, $2) }
        delegate.didCreateUploadTask(task, uploadTask: self)
    }
    
    func setHttpMethod(method: HttpMethod) {
        request.HTTPMethod = method.rawValue
    }
    
    func setValue(value: String, forHttpHeaderField field: String) {
        request.setValue(value, forHTTPHeaderField: field)
    }
    
    func resume() {
        task.resume()
        state = .Uploading
    }
    
    func suspend() {
        if state == .Uploading {
            task.suspend()
            state = .Suspending
        }
    }
    
    func cancel() {
        if state == .Uploading {
            task.cancel()
            state = .Canceled
        }
    }
    
    func updateProgress(progress: Float) {
        self.progressHandler?(progress)
    }
    
    func didComplete(_ data: NSData, _ response: NSURLResponse, _ error: NSError?) {
        state = error != nil ? .Failed : .Completed
        if (error != nil) {
            self.failureHandler?(error)
        }
        else {
            let responseData = ResponseData(response: response, data: data)
            self.successHandler?(responseData)
        }
        
        delegate.didRemoveUploadTask(task)
    }
}