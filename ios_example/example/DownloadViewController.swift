//
//  DownloadViewController.swift
//  example
//
//  Created by Le Van Nghia on 8/7/14.
//  Copyright (c) 2014 Le Van Nghia. All rights reserved.
//

import Foundation
import UIKit

class DownloadViewController : UIViewController
{
    var net: Net!
    var imgDownloadTask: DownloadTask?
    var pdfDownloadTask: DownloadTask?
    var zipDownloadTask: DownloadTask?

    @IBOutlet var imgProgressView: UIProgressView!
    @IBOutlet var pdfProgressView: UIProgressView!
    @IBOutlet var zipProgressView: UIProgressView!
   
    let imgUrl = "https://developer.apple.com/library/ios/documentation/NetworkingInternetWeb/Conceptual/NetworkingOverview/NetworkingOverview.pdf"
    let pdfUrl = "https://developer.apple.com/library/ios/documentation/iphone/conceptual/iphoneosprogrammingguide/iphoneappprogrammingguide.pdf"
    let zipUrl = "https://s3.amazonaws.com/hayageek/downloads/SimpleBackgroundFetch.zip"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        net = Net()
        net.setupSession(backgroundIdentifier: "com.nghialv.download")
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        net.eventsForBackgroundHandler = { [weak appDelegate](urlSession: NSURLSession) in
            // this will be call for every backgroud event
            urlSession.getDownloadingTasksCount{ downloadingTaskCount in
                if downloadingTaskCount == 0 {
                    NSLog("Did finish events for background")
                    if let appDel = appDelegate {
                        let localNotification = UILocalNotification()
                        localNotification.alertBody = "All files have been downloaded!"
                        UIApplication.sharedApplication().presentLocalNotificationNow(localNotification)
                
                        if let bgCompletionHandler = appDel.backgroundTransferCompletionHandler {
                            bgCompletionHandler()
                        }
                    }
                }
            }
        }
        
        imgProgressView.progress = 0.0
        pdfProgressView.progress = 0.0
        zipProgressView.progress = 0.0
    }
    
    // resume
    @IBAction func imgResumeAction() {
        self.startDownload(imgUrl, progressView: imgProgressView)
    }
   
    @IBAction func pdfResumeAction() {
        self.startDownload(pdfUrl, progressView: pdfProgressView)
    }
    
    @IBAction func zipResumeAction() {
        self.startDownload(zipUrl, progressView: zipProgressView)
    }
    
    // suspend
    @IBAction func imgSuspendAction() {
        imgDownloadTask?.suspend()
    }
    @IBAction func pdfSuspendAction() {
        pdfDownloadTask?.suspend()
    }
    
    @IBAction func zipSuspendAction() {
        zipDownloadTask?.suspend()
    }
    
    // cancel
    @IBAction func imgCancelAction() {
        imgDownloadTask?.cancel()
    }
    
    @IBAction func pdfCancelAction() {
        pdfDownloadTask?.cancel()
    }
    
    @IBAction func zipCancelAction() {
        zipDownloadTask?.cancel()
    }
    
    // all
    @IBAction func resumeAllAction(resumeBtn: UIButton) {
        self.startDownload(imgUrl, progressView: imgProgressView)
        self.startDownload(pdfUrl, progressView: pdfProgressView)
        self.startDownload(zipUrl, progressView: zipProgressView)
    }
    
    @IBAction func suspendAllAction() {
        imgDownloadTask?.suspend()
        pdfDownloadTask?.suspend()
        zipDownloadTask?.suspend()
    }
    
    @IBAction func cancelAllAction() {
        imgDownloadTask?.cancel()
        pdfDownloadTask?.cancel()
        zipDownloadTask?.cancel()
    }
    
    
    // MARK: private methods
    private func startDownload(url: String, progressView: UIProgressView) {
        let task = net.download(absoluteUrl: url, progress: { progress in
                self.setProgress(progressView, progress: progress)
            }, completionHandler: { fileUrl, error in
                if error != nil {
                    NSLog("Download failed")
                }
                else {
                    self.setProgress(progressView, progress: 1.0)
                    NSLog("Completion : \(fileUrl)")
                
                    let fileManager = NSFileManager.defaultManager()
                    let filename = url.lastPathComponent
                
                    let urls = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
                    let documentDir = urls[0] as! NSURL
                    let desUrl = documentDir.URLByAppendingPathComponent(filename)
                
                    if fileManager.fileExistsAtPath(desUrl.path!) {
                        fileManager.removeItemAtURL(desUrl, error: nil)
                    }
                
                    fileManager.copyItemAtURL(fileUrl!, toURL: desUrl, error: nil)
                }
        })
        
        switch url {
        case imgUrl:
            self.imgDownloadTask = task
        case pdfUrl:
            self.pdfDownloadTask = task
        case zipUrl:
            self.zipDownloadTask = task
        default:
            break
        }
    }
    
    private func setProgress(progressView: UIProgressView, progress: Float) {
        weak var progView = progressView
        gcd.async(.Main) {
            if progView != nil {
                progView!.progress = progress
            }
        }
    }
}