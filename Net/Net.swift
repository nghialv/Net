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

public enum HttpMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

public class Net : NSObject, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate, DownloadTaskDelegate, UploadTaskDelegate
{
    public typealias SuccessHandler = (ResponseData) -> ()
    public typealias FailureHandler = (NSError!) -> ()
    public typealias ProgressHandler = (Float) -> ()
    public typealias CompletionHandler = (NSURL?, NSError?) -> ()
    public typealias EventsForBackgroundHandler = (NSURLSession) -> ()
    
    let baseUrl: NSURL
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
    
    public init(baseUrlString: String, var headers: Dictionary<String, String>) {
        baseUrl = NSURL(string: baseUrlString)!
        requestSerializer = RequestSerialization()

        // config defaul session
        sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfig.allowsCellularAccess = true
        
        // set custom headers
        headers.updateValue("application/json,application/xml,image/png,image/jpeg", forKey: "Accept")
        sessionConfig.HTTPAdditionalHeaders = headers
        
        sessionConfig.timeoutIntervalForRequest = 30.0
        sessionConfig.timeoutIntervalForResource = 60.0
        sessionConfig.HTTPMaximumConnectionsPerHost = HTTPMaximumconnectionsPerHost
       
        session = NSURLSession(configuration: sessionConfig)
    }
    
    public convenience init(baseUrlString: String) {
        var headers = [String: String]()
        self.init(baseUrlString: baseUrlString, headers: headers)
    }

    public convenience override init() {
        var headers = [String: String]()
        self.init(baseUrlString: "", headers: headers)
    }
    
    public func setupSession(backgroundIdentifier: String? = nil) {
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
    public func invalidateAndCancel() {
        self.session.invalidateAndCancel()
        self.backgroundSession?.invalidateAndCancel()
    }
   
    public func finishTaskAndInvalidate() {
        self.session.finishTasksAndInvalidate()
        self.backgroundSession?.finishTasksAndInvalidate()
    }
    
    // GET
    public func GET(url: String, params: NSDictionary?, successHandler: SuccessHandler, failureHandler: FailureHandler)
        -> NSURLSessionTask {
        return httpRequest(.GET, url: url, params: params, successHandler: successHandler, failureHandler: failureHandler)
    }
   
    public func GET(# absoluteUrl: String, params: NSDictionary?, successHandler: SuccessHandler, failureHandler: FailureHandler)
        -> NSURLSessionTask {
        return httpRequest(.GET, url: absoluteUrl, params: params, successHandler: successHandler, failureHandler: failureHandler, isAbsoluteUrl: true)
    }
    
    // POST
    public func POST(url: String, params: NSDictionary?, successHandler: SuccessHandler, failureHandler: FailureHandler)
        -> NSURLSessionTask {
        return httpRequest(.POST, url: url, params: params, successHandler: successHandler, failureHandler: failureHandler)
    }
    
    public func POST(# absoluteUrl: String, params: NSDictionary?, successHandler: SuccessHandler, failureHandler: FailureHandler)
        -> NSURLSessionTask {
        return httpRequest(.POST, url: absoluteUrl, params: params, successHandler: successHandler, failureHandler: failureHandler, isAbsoluteUrl: true)
    }
    
    // PUT
    public func PUT(url: String, params: NSDictionary?, successHandler: SuccessHandler, failureHandler: FailureHandler)
        -> NSURLSessionTask {
        return httpRequest(.PUT, url: url, params: params, successHandler: successHandler, failureHandler: failureHandler)
    }
    
    public func PUT(# absoluteUrl: String, params: NSDictionary?, successHandler: SuccessHandler, failureHandler: FailureHandler)
        -> NSURLSessionTask {
        return httpRequest(.PUT, url: absoluteUrl, params: params, successHandler: successHandler, failureHandler: failureHandler, isAbsoluteUrl: true)
    }
    
    // DELETE
    public func DELETE(url: String, params: NSDictionary?, successHandler: SuccessHandler, failureHandler: FailureHandler)
        -> NSURLSessionTask {
        return httpRequest(.DELETE, url: url, params: params, successHandler: successHandler, failureHandler: failureHandler)
    }
    
    public func DELETE(# absoluteUrl: String, params: NSDictionary?, successHandler: SuccessHandler, failureHandler: FailureHandler) -> NSURLSessionTask {
        return httpRequest(.DELETE, url: absoluteUrl, params: params, successHandler: successHandler, failureHandler: failureHandler, isAbsoluteUrl: true)
    }

    // DOWNLOAD
    public func download(# absoluteUrl: String, startImmediately: Bool = true, progress: ProgressHandler, completionHandler: CompletionHandler) -> DownloadTask? {
        if backgroundSession == nil {
            return nil
        }
        
        let downloader = DownloadTask(session: backgroundSession!, delegate: self, absoluteUrl: absoluteUrl,
            progressHandler: progress, completionHandler: completionHandler)
        
        if startImmediately {
            downloader.resume()
        }
        
        return downloader
    }
    
    // UPLOAD
    public func upload(# absoluteUrl: String, data: NSData, startImmediately: Bool = true, progressHandler: ProgressHandler, completionHandler: (NSError?) -> ()) -> UploadTask? {
        if uploadSession == nil {
            return nil
        }
        
        let uploader = UploadTask(session: uploadSession!, delegate: self, absoluteUrl: absoluteUrl, data: data, progressHandler: progressHandler, completionHandler: completionHandler)
    
        if startImmediately {
            uploader.resume()
        }
        
        return uploader
    }
   
    public func upload(# absoluteUrl: String, params: NSDictionary, startImmediately: Bool = true, progressHandler: ProgressHandler, completionHandler: (NSError?) -> ()) -> UploadTask? {
        if uploadSession == nil {
            return nil
        }
        
        let uploader = UploadTask(session: uploadSession!, delegate: self, absoluteUrl: absoluteUrl, params: params, progressHandler: progressHandler, completionHandler: completionHandler)
        
        if startImmediately {
            uploader.resume()
        }
        
        return uploader
    }
    
    public func upload(# absoluteUrl: String, fromFile: NSURL, startImmediately: Bool = true, progressHandler: ProgressHandler, completionHandler: (NSError?) -> ()) -> UploadTask? {
        if backgroundSession == nil {
            return nil
        }
        
        let uploader = UploadTask(session: backgroundSession!, delegate: self, absoluteUrl: absoluteUrl, fromFile: fromFile, progressHandler: progressHandler, completionHandler: completionHandler)
        
        if startImmediately {
            uploader.resume()
        }
        
        return uploader
    }
    
    // MARK: NSURLSessionDelegate
    public func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession!) {
        // this will be call for every backgroud event
        eventsForBackgroundHandler?(session)
    }
    
    // MARK: NSURLSessionTaskDelegate
    public func URLSession(session: NSURLSession!, task: NSURLSessionTask!, didCompleteWithError error: NSError!) {
        if (error != nil) {
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

    public func URLSession(session: NSURLSession!, task: NSURLSessionTask!, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        // upload progress
        if task is NSURLSessionUploadTask {
            let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
            
            let uploadTask = task as NSURLSessionUploadTask
            let uploader = uploaders[uploadTask]
            uploader?.updateProgress(Float(progress))
        }
    }
    
    public func URLSession(session: NSURLSession!, task: NSURLSessionTask!, willPerformHTTPRedirection response: NSHTTPURLResponse!, newRequest request: NSURLRequest!, completionHandler: ((NSURLRequest!) -> Void)!) {
        
    }

    
    // MARK: NSURLSessionDownloadDelegate
    public func URLSession(session: NSURLSession!, downloadTask: NSURLSessionDownloadTask!, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = totalBytesExpectedToWrite == NSURLSessionTransferSizeUnknown ? -1.0 : Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        
        let downloader = downloaders[downloadTask]
        downloader?.updateProgress(Float(progress))
    }
    
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
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
    private func httpRequest(method: HttpMethod, url: String, params: NSDictionary?, successHandler: SuccessHandler, failureHandler: FailureHandler, isAbsoluteUrl: Bool = false) -> NSURLSessionTask {
        let urlString = isAbsoluteUrl ? url : "\(baseUrl.absoluteString!)\(url)"
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
            if (error != nil) {
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

public extension NSURLSession {
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
