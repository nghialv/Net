//
//  UploadViewController.swift
//  example
//
//  Created by Le Van Nghia on 8/7/14.
//  Copyright (c) 2014 Le Van Nghia. All rights reserved.
//

import Foundation
import UIKit

class UploadViewController : UIViewController
{
    var net: Net!
    
    var imgUploadTask: UploadTask?
    var pdfUploadTask: UploadTask?
    var zipUploadTask: UploadTask?
    
    @IBOutlet var imgProgressView: UIProgressView!
    @IBOutlet var pdfProgressView: UIProgressView!
    @IBOutlet var zipProgressView: UIProgressView!
    
    let imgUrl = "http://192.168.1.32:3000/files/upload_image"
    let pdfUrl = "http://192.168.1.32:3000/files/upload_pdf"
    let zipUrl = "http://192.168.1.32:3000/files/upload_zip"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        net = Net()
        net.setupSession(backgroundIdentifier: "com.nghiav.upload")
        
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        net.eventsForBackgroundHandler = { [weak appDelegate](urlSession: NSURLSession) in
            // this will be call for every backgroud event
            urlSession.getUploadingTaskCount{ uploadingTaskCount in
                if uploadingTaskCount == 0 {
                    NSLog("Did finish events for background")
                    if let appDel = appDelegate {
                        let localNotification = UILocalNotification()
                        localNotification.alertBody = "All files have been uploaded!"
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
        // upload with params
        /*
        let image = UIImage(named: "image_file")
        let imageData = UIImagePNGRepresentation(image)
        
        let params = ["number": 1, "data": imageData]
        let task = net.upload(fullUrl: imgUrl, params: params, progressHandler: { progress in
                NSLog("progress: \(progress)")
                self.setProgress(self.imgProgressView, progress: progress)
            }, completionHandler: { error in
                NSLog("Upload completed")
            })
        self.imgUploadTask = task
        */
        
        // upload with data
        /*
        let image = UIImage(named: "image_file")
        let imageData = UIImagePNGRepresentation(image)
        
        let task = net.upload(fullUrl: imgUrl, data: imageData, progressHandler: { progress in
                NSLog("progress: \(progress)")
                self.setProgress(self.imgProgressView, progress: progress)
            }, completionHandler: { error in
                NSLog("Upload completed")
            })
        self.imgUploadTask = task
        */
        
        // upload with file
        let path = NSBundle.mainBundle().pathForResource("image_file", ofType: "png")
        let fileUrl = NSURL(fileURLWithPath: path!)
        startUpload(imgUrl, file: fileUrl!, progressView: imgProgressView)
    }
    
    @IBAction func pdfResumeAction() {
        let path = NSBundle.mainBundle().pathForResource("pdf_file", ofType: "pdf")
        let fileUrl = NSURL(fileURLWithPath: path!)
        startUpload(pdfUrl, file: fileUrl!, progressView: pdfProgressView)
    }
    
    @IBAction func zipResumeAction() {
        let path = NSBundle.mainBundle().pathForResource("zip_file", ofType: "zip")
        let fileUrl = NSURL(fileURLWithPath: path!)
        startUpload(zipUrl, file: fileUrl!, progressView: zipProgressView)
    }
    
    // suspend
    @IBAction func imgSuspendAction() {
        imgUploadTask?.suspend()
    }
    @IBAction func pdfSuspendAction() {
        pdfUploadTask?.suspend()
    }
    
    @IBAction func zipSuspendAction() {
        zipUploadTask?.suspend()
    }
    
    // cancel
    @IBAction func imgCancelAction() {
        imgUploadTask?.cancel()
    }
    
    @IBAction func pdfCancelAction() {
        pdfUploadTask?.cancel()
    }
    
    @IBAction func zipCancelAction() {
        zipUploadTask?.cancel()
    }
    
    // all
    @IBAction func resumeAllAction(resumeBtn: UIButton) {
        imgResumeAction()
        pdfResumeAction()
        zipResumeAction()
    }
    
    @IBAction func suspendAllAction() {
        imgUploadTask?.suspend()
        pdfUploadTask?.suspend()
        zipUploadTask?.suspend()
    }
    
    @IBAction func cancelAllAction() {
        imgUploadTask?.cancel()
        pdfUploadTask?.cancel()
        zipUploadTask?.cancel()
    }
    
    
    // MARK: private methods
    private func startUpload(url: String, file: NSURL, progressView: UIProgressView) {
        let task = net.upload(absoluteUrl: url, fromFile: file, progressHandler: { progress in
                self.setProgress(progressView, progress: progress)
            }, completionHandler: { error in
                if error != nil {
                    NSLog("Upload failed : \(error)")
                }
                else {
                    NSLog("Upload completed")
                }
        })
        
        switch url {
        case imgUrl:
            self.imgUploadTask = task
        case pdfUrl:
            self.pdfUploadTask = task
        case zipUrl:
            self.zipUploadTask = task
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