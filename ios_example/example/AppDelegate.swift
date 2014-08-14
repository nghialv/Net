//
//  AppDelegate.swift
//  example
//
//  Created by Le Van Nghia on 8/2/14.
//  Copyright (c) 2014 Le Van Nghia. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
                            
    var window: UIWindow?
    var backgroundTransferCompletionHandler: (() -> Void)?

    func application(application: UIApplication!, didFinishLaunchingWithOptions launchOptions: NSDictionary!)
        -> Bool {
        return true
    }

    func application(application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: () -> Void) {
        backgroundTransferCompletionHandler = completionHandler
        NSLog("handle event for background session")
    }
    
    func applicationDidEnterBackground(application: UIApplication!) {
        NSLog("App did enter background")
    }

    func applicationWillEnterForeground(application: UIApplication!) {
    }

    func applicationDidBecomeActive(application: UIApplication!) {
    }

    func applicationWillTerminate(application: UIApplication!) {
    }

}

