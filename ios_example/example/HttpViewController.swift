//
//  ViewController.swift
//  example
//
//  Created by Le Van Nghia on 8/2/14.
//  Copyright (c) 2014 Le Van Nghia. All rights reserved.
//

import UIKit

class HttpViewController: UIViewController, NSXMLParserDelegate {
    @IBOutlet var imageView: UIImageView!
    var net: Net!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // create net instance
        net = Net(baseUrlString: "http://192.168.1.32:3000/http_requests/")
    }

    // MARK: NSXMLParser delegate
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        NSLog("did start element : \(elementName)")
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String) {
    }
    
    // MARK: Actions
    @IBAction func jsonGetActions() {
        let url = "get_json"
        let params = ["integerNumber": 1,
            "doubleNumber": 2.0,
            "string": "hello",
            "array": [10, 20, 30],
            "dictionary": ["x": 100.0, "y": 200.0]]
        
        net.GET(url, params: params, successHandler: { responseData in
                let result = try? responseData.json()
                NSLog("result \(result)")
            }, failureHandler: { error in
                NSLog("Error")
            })
    }
    
    @IBAction func xmlGetActions() {
        let url = "simple.xml"
        
        net.GET(url, params: nil, successHandler: {
            [weak self]responseData in
                if let s = self {
                    let _: Bool
                    do {
                        try responseData.parseXml(s)
                        _ = true
                    } catch _ {
                        _ = false
                    }
                }
            }, failureHandler: { error in
                NSLog("Error")
            })
    }
    
    @IBAction func imageGetActions() {
        self.imageView.image = nil
        
        let url = "image.png"
        net.GET(url, params: nil, successHandler: {
            [weak self]responseData in
                gcd.async(.Main) {
                    if let s = self {
                        do {
                            s.imageView.image = try responseData.image()
                        } catch _ {
                            s.imageView.image = nil
                        }
                    }
                }
            }, failureHandler: { error in
                NSLog("Error")
            })
    }
    
    @IBAction func urlEncodedPostActions() {
        let url = "post_url_encoded"
        let params = ["string": "test",
            "integerNumber": 1,
            "floatNumber": 1.5,
            "array": [10, 20, 30],
            "dictionary": ["x": 100.0, "y": 200.0]]
        
        net.POST(url, params: params, successHandler: {
            responseData in
                let result = try? responseData.json()
                NSLog("result: \(result)")
            }, failureHandler: { error in
                NSLog("Error")
            })
    }
    
    @IBAction func multiPartPostActions() {
        let url = "post_multi_part"
        let img = UIImage(named: "puqiz_icon")
        
        let params = ["string": "test",
            "integerNumber": 1,
            "floatNumber": 1.5,
            "array": [10, 20, 30],
            "dictionary": ["x": 100.0, "y": 200.0],
            "icon": NetData(pngImage: img!, filename: "myIcon")]
        
        net.POST(url, params: params, successHandler: {
            responseData in
                let result = try? responseData.json()
                NSLog("result: \(result)")
            }, failureHandler: { error in
                NSLog("Error")
            })
    }
   
    @IBAction func basicAuthenticationAction() {
        
    }
    
    @IBAction func batchAction() {
        
    }
}

