//
//  Net.swift
//  Net
//
//  Created by Le Van Nghia on 7/31/14.
//  Copyright (c) 2014 Le Van Nghia. All rights reserved.
//

import Foundation

// TODO: authentication
// TODO: cache
// TODO: batch

enum HttpMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

class Net : NSObject, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate, DownloadTaskDelegate, UploadTaskDelegate
{
    typealias SuccessHandler = (ResponseData) -> ()
    typealias FailureHandler = (NSError!) -> ()
    typealias ProgressHandler = (Float) -> ()
    typealias ComplitionHandler = (NSURL?, NSError?) -> ()
    typealias EventsForBackgroundHandler = (NSURLSession) -> ()
    
    var baseUrl: NSURL
    var allowsCellularAccess = true
    var timeoutIntervalForRequest = 30.0
    var timeoutIntervalForResource = 60.0
    var HTTPMaximumconnectionsPerHost: Int = 5
    var eventsForBackgroundHandler: EventsForBackgroundHandler?
    
    private var session: NSURLSession
    private var sessionConfig: NSURLSessionConfiguration
   
    private var backgroundSession: NSURLSession?
    private var backgroundSessionConfig: NSURLSessionConfiguration?
    
    private var uploadSession: NSURLSession?

    private var requestSerializer: RequestSerialization

    // download tasks dictionary
    private var downloaders = [NSURLSessionDownloadTask: DownloadTask]()
    // upload tasks dictionary
    private var uploaders = [NSURLSessionUploadTask: UploadTask]()
    
    init(baseUrlString: String) {
        baseUrl = NSURL(string: baseUrlString)
        requestSerializer = RequestSerialization()
        
        // config defaul session
        sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfig.allowsCellularAccess = true
        sessionConfig.HTTPAdditionalHeaders = ["Accept": "application/json,application/xml,image/png,image/jpeg"]
        sessionConfig.timeoutIntervalForRequest = 30.0
        sessionConfig.timeoutIntervalForResource = 60.0
        sessionConfig.HTTPMaximumConnectionsPerHost = HTTPMaximumconnectionsPerHost
       
        session = NSURLSession(configuration: sessionConfig)
    }
    
    convenience override init() {
        self.init(baseUrlString: "")
    }
    
    func setupSession(backgroundIdentifier: String? = nil) {
        if backgroundIdentifier != nil {
            if backgroundSession == nil {
                //backgroundSessionConfig = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(backgroundIdentifier!)
                backgroundSessionConfig = NSURLSessionConfiguration.backgroundSessionConfiguration(backgroundIdentifier!)
                backgroundSessionConfig!.HTTPMaximumConnectionsPerHost = HTTPMaximumconnectionsPerHost
                
                backgroundSession = NSURLSession(configuration: backgroundSessionConfig, delegate: self, delegateQueue: nil)
            }
        }
        else {
            backgroundSession = NSURLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        }
        uploadSession = NSURLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
    }
    
    // MARK: Session manager
    func invalidateAndCancel() {
        self.session.invalidateAndCancel()
        self.backgroundSession?.invalidateAndCancel()
    }
   
    func finishTaskAndInvalidate() {
        self.session.finishTasksAndInvalidate()
        self.backgroundSession?.finishTasksAndInvalidate()
    }
    
    // GET
    func GET(url: String, params: NSDictionary?, successHandler: SuccessHandler, failureHandler: FailureHandler)
        -> NSURLSessionTask {
        return httpRequest(.GET, url: url, params: params, successHandler: successHandler, failureHandler: failureHandler)
    }
   
    func GET(# fullUrl: String, params: NSDictionary?, successHandler: SuccessHandler, failureHandler: FailureHandler)
        -> NSURLSessionTask {
        return httpRequest(.GET, url: fullUrl, params: params, successHandler: successHandler, failureHandler: failureHandler, isFullUrl: true)
    }
    
    // POST
    func POST(url: String, params: NSDictionary?, successHandler: SuccessHandler, failureHandler: FailureHandler)
        -> NSURLSessionTask {
        return httpRequest(.POST, url: url, params: params, successHandler: successHandler, failureHandler: failureHandler)
    }
    
    func POST(# fullUrl: String, params: NSDictionary?, successHandler: SuccessHandler, failureHandler: FailureHandler)
        -> NSURLSessionTask {
        return httpRequest(.POST, url: fullUrl, params: params, successHandler: successHandler, failureHandler: failureHandler, isFullUrl: true)
    }
    
    // PUT
    func PUT(url: String, params: NSDictionary?, successHandler: SuccessHandler, failureHandler: FailureHandler)
        -> NSURLSessionTask {
        return httpRequest(.PUT, url: url, params: params, successHandler: successHandler, failureHandler: failureHandler)
    }
    
    func PUT(# fullUrl: String, params: NSDictionary?, successHandler: SuccessHandler, failureHandler: FailureHandler)
        -> NSURLSessionTask {
        return httpRequest(.PUT, url: fullUrl, params: params, successHandler: successHandler, failureHandler: failureHandler, isFullUrl: true)
    }
    
    // DELETE
    func DELETE(url: String, params: NSDictionary?, successHandler: SuccessHandler, failureHandler: FailureHandler)
        -> NSURLSessionTask {
        return httpRequest(.DELETE, url: url, params: params, successHandler: successHandler, failureHandler: failureHandler)
    }
    
    func DELETE(# fullUrl: String, params: NSDictionary?, successHandler: SuccessHandler, failureHandler: FailureHandler) -> NSURLSessionTask {
        return httpRequest(.DELETE, url: fullUrl, params: params, successHandler: successHandler, failureHandler: failureHandler, isFullUrl: true)
    }

    // DOWNLOAD
    func download(# fullUrl: String, startImmediately: Bool = true, progress: ProgressHandler, complitionHandler: ComplitionHandler) -> DownloadTask? {
        if backgroundSession == nil {
            return nil
        }
        
        let downloader = DownloadTask(session: backgroundSession!, delegate: self, fullUrl: fullUrl,
            progressHandler: progress, complitionHandler: complitionHandler)
        
        if startImmediately {
            downloader.resume()
        }
        
        return downloader
    }
    
    // UPLOAD
    func upload(# fullUrl: String, data: NSData, startImmediately: Bool = true, progressHandler: ProgressHandler, complitionHandler: (NSError?) -> ()) -> UploadTask? {
        if uploadSession == nil {
            return nil
        }
        
        let uploader = UploadTask(session: uploadSession!, delegate: self, fullUrl: fullUrl, data: data, progressHandler: progressHandler, complitionHandler: complitionHandler)
    
        if startImmediately {
            uploader.resume()
        }
        
        return uploader
    }
   
    func upload(# fullUrl: String, params: NSDictionary, startImmediately: Bool = true, progressHandler: ProgressHandler, complitionHandler: (NSError?) -> ()) -> UploadTask? {
        if uploadSession == nil {
            return nil
        }
        
        let uploader = UploadTask(session: uploadSession!, delegate: self, fullUrl: fullUrl, params: params, progressHandler: progressHandler, complitionHandler: complitionHandler)
        
        if startImmediately {
            uploader.resume()
        }
        
        return uploader
    }
    
    func upload(# fullUrl: String, fromFile: NSURL, startImmediately: Bool = true, progressHandler: ProgressHandler, complitionHandler: (NSError?) -> ()) -> UploadTask? {
        if backgroundSession == nil {
            return nil
        }
        
        let uploader = UploadTask(session: backgroundSession!, delegate: self, fullUrl: fullUrl, fromFile: fromFile, progressHandler: progressHandler, complitionHandler: complitionHandler)
        
        if startImmediately {
            uploader.resume()
        }
        
        return uploader
    }
    
    // MARK: NSURLSessionDelegate
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession!) {
        // this will be call for every backgroud event
        eventsForBackgroundHandler?(session)
    }
    
    // MARK: NSURLSessionTaskDelegate
    func URLSession(session: NSURLSession!, task: NSURLSessionTask!, didCompleteWithError error: NSError!) {
        if error {
            if task is NSURLSessionDownloadTask {
                let downloadTask = task as NSURLSessionDownloadTask
                let downloader = downloaders[downloadTask]
                downloader?.didComplete(nil, error: error)
                downloaders.removeValueForKey(downloadTask)
            }
            else if task is NSURLSessionUploadTask {
                let uploadTask = task as NSURLSessionUploadTask
                let uploader = uploaders[uploadTask]
                uploader?.didComplete(error)
                uploaders.removeValueForKey(uploadTask)
            }
        }
        else {
            if task is NSURLSessionUploadTask {
                let uploadTask = task as NSURLSessionUploadTask
                let uploader = uploaders[uploadTask]
                uploader?.didComplete(nil)
                uploaders.removeValueForKey(uploadTask)
            }
        }
    }

    func URLSession(session: NSURLSession!, task: NSURLSessionTask!, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        // upload progress
        if task is NSURLSessionUploadTask {
            let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
            
            let uploadTask = task as NSURLSessionUploadTask
            let uploader = uploaders[uploadTask]
            uploader?.updateProgress(Float(progress))
        }
    }
    
    func URLSession(session: NSURLSession!, task: NSURLSessionTask!, willPerformHTTPRedirection response: NSHTTPURLResponse!, newRequest request: NSURLRequest!, completionHandler: ((NSURLRequest!) -> Void)!) {
        
    }

    
    // MARK: NSURLSessionDownloadDelegate
    func URLSession(session: NSURLSession!, downloadTask: NSURLSessionDownloadTask!, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = totalBytesExpectedToWrite == NSURLSessionTransferSizeUnknown ? -1.0 : Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        
        let downloader = downloaders[downloadTask]
        downloader?.updateProgress(Float(progress))
    }
    
    func URLSession(session: NSURLSession!, downloadTask: NSURLSessionDownloadTask!, didFinishDownloadingToURL location: NSURL!) {
        var downloader = downloaders[downloadTask]
        downloader?.didComplete(location, error: nil)
        downloaders.removeValueForKey(downloadTask)
    }
   
    
    // MARK: DownloadTaskDelegate
    func didCreateDownloadTask(task: NSURLSessionDownloadTask, downloadTask: DownloadTask) {
        downloaders[task] = downloadTask
    }
    
    func didRemoveDownloadTask(task: NSURLSessionDownloadTask) {
        downloaders.removeValueForKey(task)
    }
    
    // MARK: UploadTaskDelegate
    func didCreateUploadTask(task: NSURLSessionUploadTask, uploadTask: UploadTask) {
        uploaders[task] = uploadTask
    }
    
    func didRemoveUploadTask(task: NSURLSessionUploadTask) {
        uploaders.removeValueForKey(task)
    }
    
    
    // MARK: Private methods
    /**
    *  create http request instance
    *
    *  @param HttpMethod     method type: GET, POST, PUT, DELETE
    *  @param String         url (the part start from end of base url)
    *  @param NSDictionary?  parameters
    *  @param SuccessHandler success handler closure
    *  @param FailureHandler failure handler closure
    *
    *  @return request instance
    */
    private func httpRequest(method: HttpMethod, url: String, params: NSDictionary?, successHandler: SuccessHandler, failureHandler: FailureHandler, isFullUrl: Bool = false) -> NSURLSessionTask {
        let urlString = isFullUrl ? url : NSURL(string: url, relativeToURL: baseUrl).absoluteString
        NSLog(urlString)
        
        let request = requestSerializer.requestWithMethod(method, urlString: urlString, params: params, error: nil)
        let task = createSessionTaskWithRequest(request, successHandler: successHandler, failureHandler: failureHandler)
        task.resume()
        
        return task
    }
    
    /**
    *  create data task session for request
    *
    *  @param NSURLRequest   request
    *  @param SuccessHandler success handler closure
    *  @param FailureHandler failure handler closure
    *
    *  @return session task
    */
    private func createSessionTaskWithRequest(request: NSURLRequest, successHandler: SuccessHandler, failureHandler: FailureHandler) -> NSURLSessionTask {
        let task = session.dataTaskWithRequest(request, completionHandler:{
            (data, response, error) in
            if error {
                failureHandler(error)
            }
            else {
                let responseData = ResponseData(response: response, data: data)
                successHandler(responseData)
            }
        })
        
        return task
    }
}

extension NSURLSession {
    func getDownloadingTasksCount(completionHandler: (Int) -> Void) {
        self.getTasksWithCompletionHandler{ dataTasks, uploadTasks, downloadTasks in
            completionHandler(downloadTasks.count)
        }
    }
    
    func getUploadingTaskCount(completionHandler: (Int) -> Void) {
        self.getTasksWithCompletionHandler{ dataTasks, uploadTasks, downloadTasks in
            completionHandler(uploadTasks.count)
        }
    }
    
    func getTransferingTaskCount(completionHandler: (Int) -> Void) {
        self.getTasksWithCompletionHandler{ dataTask, uploadTasks, downloadTasks in
            let count = uploadTasks.count + downloadTasks.count
            completionHandler(count)
        }
    }
}
