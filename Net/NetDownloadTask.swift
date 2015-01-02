//
//  NetDownloadTask.swift
//  Net
//
//  Created by Le Van Nghia on 8/4/14.
//  Copyright (c) 2014 Le Van Nghia. All rights reserved.
//

import Foundation

protocol DownloadTaskDelegate {
    func didCreateDownloadTask(task: NSURLSessionDownloadTask, downloadTask: DownloadTask)
    func didRemoveDownloadTask(task: NSURLSessionDownloadTask)
}

public class DownloadTask
{
    enum State {
        case Init, Downloading, Suspending, Canceled, Completed, Failed
    }
    
    typealias ProgressHandler = (Float) -> ()
    typealias CompletionHandler = (NSURL?, NSError?) -> ()
   
    private var session: NSURLSession
    private var delegate: DownloadTaskDelegate
    
    private var task: NSURLSessionDownloadTask
    private var resumeData: NSData?
    private var request: NSMutableURLRequest
    
    private var progressHandler: ProgressHandler?
    private var completionHandler: CompletionHandler
    
    private var state: State = .Init
    
    init(session: NSURLSession, delegate: DownloadTaskDelegate, absoluteUrl: String, progressHandler: ProgressHandler?, completionHandler: CompletionHandler) {
        self.session = session
        self.delegate = delegate
        
        // create task
        let url = NSURL(string: absoluteUrl)
        request = NSMutableURLRequest(URL: url!)
        // TODO: config for request
        request.HTTPMethod = HttpMethod.GET.rawValue
        task = session.downloadTaskWithRequest(request)
        
        self.progressHandler = progressHandler
        self.completionHandler = completionHandler
        
        delegate.didCreateDownloadTask(task, downloadTask: self)
    }
    
    /**
    *  A download can be resumed with resumeData only if the following conditions are met:
    *  - The resource has not changed since you first requested it
    *  - The task is an HTTP or HTTPS GET request
    *  - The server provides either the ETag or Last-Modified header (or both) in its response
    *  - The server supports byte-range requests
    *  - The temporary file hasn’t been deleted by the system in response to disk space pressure
    */
    public func resume() {
        if state == .Canceled || state == .Failed {
            if resumeData != nil {
                task = session.downloadTaskWithResumeData(resumeData!)
            }
            else {
                task = session.downloadTaskWithRequest(request)
            }
            delegate.didCreateDownloadTask(task, downloadTask: self)
        }
        
        task.resume()
        state = .Downloading
    }
   
    /**
    * Temporarily suspends download task
    *
    *  @return
    */
    public func suspend() {
        if state == .Downloading {
            task.suspend()
            state = .Suspending
        }
    }
    
    /**
    *  Cancels a download and calls a callback with resume data for later use
    *
    *  @return
    */
    public func cancel(byProducingResumeData: Bool = true) {
        if state == .Downloading {
            if byProducingResumeData {
                task.cancelByProducingResumeData{
                    [weak self] resumeData in
                    if let s = self {
                        s.resumeData = resumeData
                    }
                }
            }
            else {
                self.resumeData = nil
                task.cancel()
            }
            delegate.didRemoveDownloadTask(task)
            state = .Canceled
        }
    }
    
    
    public func updateProgress(progress: Float) {
        self.progressHandler?(progress)
    }
    
    public func didComplete(url: NSURL?, error: NSError?) {
        state = error != nil ? .Failed : .Completed
        self.completionHandler(url, error)
    }
}
