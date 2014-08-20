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
    
    private var session: NSURLSession
    private var delegate: UploadTaskDelegate
    private var task: NSURLSessionUploadTask!
    private var request: NSMutableURLRequest
    
    private var progressHandler: ProgressHandler?
    private var completionHandler: CompletionHandler
    
    private var state: State = .Init
   
    init(_ session: NSURLSession,_ delegate: UploadTaskDelegate,_ absoluteUrl: String,_ progressHandler: ProgressHandler?,_ completionHandler: CompletionHandler) {
        self.session = session
        self.delegate = delegate
        let url = NSURL(string: absoluteUrl)
        self.request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = HttpMethod.POST.toRaw()
    
        self.progressHandler = progressHandler
        self.completionHandler = completionHandler
    }
    
    convenience init(session: NSURLSession, delegate: UploadTaskDelegate, absoluteUrl: String, data: NSData, progressHandler: ProgressHandler?, completionHandler: CompletionHandler) {
        
        self.init(session, delegate, absoluteUrl, progressHandler, completionHandler)
        
        // TODO: config for request
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        task = session.uploadTaskWithRequest(request, fromData: data)
        
        delegate.didCreateUploadTask(task, uploadTask: self)
    }
   
    convenience init(session: NSURLSession, delegate: UploadTaskDelegate, absoluteUrl: String, params: NSDictionary, progressHandler: ProgressHandler?, completionHandler: CompletionHandler) {
        
        self.init(session, delegate, absoluteUrl, progressHandler, completionHandler)
        
        let boundary = "NET-UPLOAD-boundary-\(arc4random())-\(arc4random())"
        let paramsData = NetHelper.dataFromParamsWithBoundary(params, boundary: boundary)
        let contentType = "multipart/form-data; boundary=\(boundary)"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("\(paramsData.length)", forHTTPHeaderField: "Content-Length")
        
        task = session.uploadTaskWithRequest(request, fromData: paramsData)
        
        delegate.didCreateUploadTask(task, uploadTask: self)
    }
    
    convenience init(session: NSURLSession, delegate: UploadTaskDelegate, absoluteUrl: String, fromFile: NSURL, progressHandler: ProgressHandler?, completionHandler: CompletionHandler) {
        
        self.init(session, delegate, absoluteUrl, progressHandler, completionHandler)
        
        task = session.uploadTaskWithRequest(request, fromFile: fromFile)
        delegate.didCreateUploadTask(task, uploadTask: self)
    }
    
    func setHttpMethod(method: HttpMethod) {
        request.HTTPMethod = method.toRaw()
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
    
    func didComplete(error: NSError?) {
        state = error != nil ? .Failed : .Completed
        completionHandler(error)
    }
}