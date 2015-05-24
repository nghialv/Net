Net
=====
Net is a HttpRequest wrapper written in Swift

Features
-----
- [x] GET, POST, PUT, DELETE method
- [x] Powerful request params: nested params, number, string, dic, array, image, data
- [x] Json, Image, Xml Response
- [x] Download file: resume, suspend, cancel
- [x] Upload file, data, params(multi-part)
- [x] Progress closure
- [x] Background donwload, upload
- [x] Authentication
- [x] Batch of operations
- [x] BaseURL
- [x] Customizable header

Demo app
-----
![screenshot](https://dl.dropboxusercontent.com/u/8556646/screenshot2.png)

Usage
-----
Use one of the following methods to create a Net instance

```swift
// without baseURL
let net = Net()

// with baseURL
let net = Net(baseUrlString: "http://www.puqiz.com/") 
```

### HttpRequest

###### `GET` Request

```swift
let url = "get_path"
let params = ["integerNumber": 1, "doubleNumber": 2.0, "string": "hello"]

net.GET(url, params: params, successHandler: { responseData in
		let result = responseData.json(error: nil)
		NSLog("result \(result)")
	}, failureHandler: { error in
		NSLog("Error")
	})

// you can also make a request with absolute url
let url = "http://www.puqiz.com/get_path"
net.GET(absoluteUrl: url, params: params, successHandler: { responseData in
		let result = responseData.json(error: nil)
		NSLog("result \(result)")
	}, failureHandler: { error in
		NSLog("Error")
	})
```

You can also use nested params

```swift
// nested params
let params = ["string": "test",
            "integerNumber": 1,
            "floatNumber": 1.5,
            "array": [10, 20, 30],
            "dictionary": ["x": 100.0, "y": 200.0],
            "image": NetData(pngImage: img, filename: "myIcon")]
```

By using responseData in sucessHandler closure you can quickly
* get json dictionary
* get image
* parse xml

for GET, POST, PUT, DELETE request.

```swift
// get json dictionary from response data
let jsonDic = responseData.json(error: error)

// get image from response data
let image = responseData.image()

// parse xml with delegate
let result = responseData.parseXml(delegate: self)
```

###### `POST` Request
Net will automatically check your params to send request as a URL-Encoded request or a Multi-Part request. So you can easily post with number, string, image or binary data.

* URL-Encoded Request

```swift
let url = "post_path"
let params = ["string": "test", "integerNumber": 1, "floatNumber": 1.5]
        
net.POST(url, params: params, successHandler: { responseData in
		let result = responseData.json(error: nil)
		NSLog("result: \(result)")
	}, failureHandler: { error in
		NSLog("Error")
	})
```

* Multi-Part Request

```swift
let url = "post_path"
let img = UIImage(named: "puqiz_icon")
        
let params = ["string": "test", "integerNumber": 1,
            "icon": NetData(pngImage: img, filename: "myIcon")]
        
net.POST(url, params: params, successHandler: { responseData in
		let result = responseData.json(error: nil)
		NSLog("result: \(result)")
	}, failureHandler: { error in
		NSLog("Error")
	})
```

###### `PUT` Request
```swift
let url = "put_path"
let params = ["string": "test", "integerNumber": 1, "floatNumber": 1.5]
        
net.PUT(url, params: params, successHandler: { responseData in
		let result = responseData.json(error: nil)
		NSLog("result: \(result)")
	}, failureHandler: { error in
		NSLog("Error")
	})
```

###### `DELETE` Request
```swift
let url = "delete_path"
let params = ["id": 10]
        
net.DELETE(url, params: params, successHandler: { responseData in
		NSLog("result: \(result)")
	}, failureHandler: { error in
		NSLog("Error")
	})
```

### Task
Before using download/upload function you have to call `setupSession` method to setup the session.

```swift
// setup session without backgroundIdentifier
net.setupSession()
```
To perform background downloads or uploads, you have to call `setupSession` method with a background identifier string. Then your download/upload tasks can be run even when the app is suspended, exits or crashes. 

```swift
// setup session with backgroundIdentifier
net.setupSession(backgroundIdentifier: "com.nghialv.download")

// you can set eventsForBackgroundHandler closure
// this closure will be invoked when a task is completed in the background
net.eventsForBackgroundHandler = { urlSession in
		urlSession.getDownloadingTasksCount{ downloadingTaskCount in
		if downloadingTaskCount == 0 {
			NSLog("All files have been downloaded!")
		}
	}
}
``` 

###### Download
```swift
let downloadTask = net.download(absoluteUrl: url, progress: { progress in
		NSLog("progress \(progress)")
	}, completionHandler: { fileUrl, error in
		if error != nil {
			NSLog("Download failed")
		}
		else {
			NSLog("Downloaded to  : \(fileUrl)")
		}
	})

// you can control your task
downloadTask.resume()
downloadTask.suspend()
downloadTask.cancel()
```

###### Upload
* Upload with file path

```swift
let task = net.upload(absoluteUrl: url, fromFile: file, progressHandler: { progress in
		NSLog("progress \(progress)")
	}, completionHandler: { error in
		if error != nil {
			NSLog("Upload failed : \(error)")
		}
		else {
			NSLog("Upload completed")
		}
	})
```

* Upload with data

```swift
let yourData = NSData(...)
        
net.upload(absoluteUrl: url, data: yourData, progressHandler: { progress in
		NSLog("progress: \(progress)")
	}, completionHandler: { error in
		NSLog("Upload completed")
	})
```

* Upload with params

```swift
let image = UIImage(named: "image_file")
let imageData = UIImagePNGRepresentation(image)
let params = ["number": 1, "string": "net", "data": imageData]

net.upload(absoluteUrl: imgUrl, params: params, progressHandler: { progress in
		NSLog("progress: \(progress)")
	}, completionHandler: { error in
		NSLog("Upload completed")
	})
```
By default, the upload task will be performed as POST method and 

* `Content-Type` = `application/octet-stream` (upload with file or data)
* `Content-Type` = `multipart/form-data` (upload with params)

But you can configure the upload task before resuming.

```swift
// set method
yourUploadTask.setHttpMethod(.PUT)

// set header field
yourUploadTask.setValue(value: "your_value", forHttpHeaderField: "header_field")
```

Integration
-----
Just drag Net folder to the project tree
