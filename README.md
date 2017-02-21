# ETNetwork

## Requirements

- iOS 8.0+ 
- Xcode 8.1+
- Swift 3.0.1

## What

ETNetwork is is a high level request util based on [Alamofire](https://github.com/Alamofire/Alamofire), take [YTKNetwork](https://github.com/yuantiku/YTKNetwork/) as reference. 

## Features
 * Response can be cached by expiration time
 * Response can be cached by version number
 * Set common base URL
 * block and delegate callback

## Why using CryptoSwift
because using md5 in swift is complicated. http://iosdeveloperzone.com/2014/10/03/using-commoncrypto-in-swift/ , and I don't want to impor Obj-c file. CryptoSwift is good.
## How to use
```bash
$ git clone https://github.com/anpufeng/ETNetwork/

carthage update
```
open `iOS Sample.xcodeproj`, run the sample project
##every request, implement `RequestProtocol` 
```swift
import ETNetwork

class GetApi: NetRequest {
    
    var bar: String
    init(bar: String) {
        self.bar = bar
        super.init()
    }
}

extension GetApi: RequestProtocol {
    var method: RequestMethod { return .get }
    var taskType: TaskType { return .data }
    var requestURL: String { return "/get" }
    var parameters:  [String: AnyObject]? {
        return ["foo": bar as AnyObject]
    }
}
```
###cache the request, implement `RequestCacheProtocol` 
```swift
extension GetApi: RequestCacheProtocol {
    var cacheVersion: UInt64 { return 1 }
    var cacheSeconds: Int { return 60 }
}

```

call `GetApi `

```swift
dataApi = GetApi(bar: "GetApi")
dataApi?.start(ignoreCache: cacheSwitch.isOn)
dataApi?.responseJSON({ [weak self] (json, error) -> Void in
    
    guard let strongSelf = self else {
        return
    }
    strongSelf.refreshControl?.endRefreshing()
    if (error != nil) {
        print("==========error: \(error)")
        strongSelf.bodyCell.textLabel?.text = error?.localizedDescription
    } else {
        strongSelf.headerCell.textLabel?.text = strongSelf.dataApi?.debugDescription
        strongSelf.bodyCell.textLabel?.text = "\(json.debugDescription)"
        print(strongSelf.dataApi.debugDescription)
        print("==========json: \(json)")
    }
    
    strongSelf.tableView.reloadData()
})

```

###download request, implement `RequestDownloadProtocol`
```swift
class GetDownloadApi: NetRequest {
    
    var bar: String
    init(bar: String) {
        self.bar = bar
        super.init()
    }
}

extension GetDownloadApi: RequestProtocol {
    var method: RequestMethod { return .get }
    var taskType: TaskType { return .download }
    //http://dldir1.qq.com/qqfile/QQforMac/QQ_V4.0.6.dmg
    //http://ftp-apk.pconline.com.cn/b5cb691afcce3906dc11602df610f212/pub/download/201010/freewifi_2232_0909.apk
    var requestURL: String { return "http://ftp-apk.pconline.com.cn/b5cb691afcce3906dc11602df610f212/pub/download/201010/freewifi_2232_0909.apk" }
    var parameters:  [String: AnyObject]? {
        return nil
    }
}


extension GetDownloadApi: RequestCacheProtocol {
    
    //cache
    var cacheSeconds: Int { return -1 }
}

extension GetDownloadApi: RequestDownloadProtocol {
    
}

```
###upload request, implement `RequestUploadProtocol`
```swift
import ETNetwork

class UploadStreamApi: NetRequest {

    var jsonData: Data
    var imgData: Data
    init(jsonData : Data, imgData: Data) {
        self.jsonData = jsonData
        self.imgData = imgData
        super.init()
    }
}

extension UploadStreamApi: RequestProtocol {
    var method: RequestMethod { return .post }
    var taskType: TaskType { return .uploadFormData }
    var requestURL: String { return "/post" }
    var parameters:  [String: AnyObject]? {
        return ["upload": "UploadStreamApiParameters" as AnyObject]
    }

    var headers: [String: String]? { return ["UploadDataApi": "UploadDataApiHeader"]  }
}

extension UploadStreamApi: RequestUploadProtocol {
    var formData: [UploadFormProtocol]? {
        var forms: [UploadFormProtocol] = []
        let jsonInputStream = InputStream(data: jsonData)
        let jsonStreamWrap = UploadFormStream(name: "streamJson", stream: jsonInputStream, length: UInt64(jsonData.count), fileName: "streamJsonFileName", mimeType: "text/plain")

        let imgInputStream = InputStream(data: imgData)
        let imgStreamWrap = UploadFormStream(name: "streamImg", stream: imgInputStream, length: UInt64(imgData.count), fileName: "steamImgFileName", mimeType: "image/png")

        forms.append(jsonStreamWrap)
        forms.append(imgStreamWrap)

        let dataPath = Bundle.main.path(forResource: "test", ofType: "txt")
        if let dataPath = dataPath {
            if let data = try? Data(contentsOf: URL(fileURLWithPath: dataPath)) {
                let dataForm = UploadFormData(name: "testtxt", data: data)
                forms.append(dataForm)
            }
        }

        let fileURL = Bundle.main.url(forResource: "upload2", withExtension: "png")
        if let fileURL = fileURL {
            let fileWrap = UploadFormFileURL(name: "upload2png", fileURL: fileURL)
            forms.append(fileWrap)
        }

        return forms
    }
}
```
###know the progress
```swift
downloadApi?.start(manager, ignoreCache: true)

        //        if let data = downloadApi?.cachedData {
        //            print("cached data: \(data)")
        //        }
        downloadApi?.progress({ [weak self] (totalBytesRead, totalBytesExpectedToRead) -> Void in
            guard let strongSelf = self else { return }
            print("totalBytesRead: \(totalBytesRead), totalBytesExpectedToRead: \(totalBytesExpectedToRead)")
            let percent = Float(totalBytesRead)/Float(totalBytesExpectedToRead)
            print("percent: \(percent)")
            DispatchQueue.main.async(execute: { () -> Void in
                strongSelf.processView.progress = percent
                let read = String(format: "%.2f", Float(totalBytesRead)/1024)
                let total = String(format: "%.2f", Float(totalBytesExpectedToRead)/1024)
                strongSelf.readLabel.text = "read: \(read) KB"
                strongSelf.totalLabel.text = "total: \(total) KB"
            })
           
        })
```
###batch request
```swift
let one = GetApi(bar: "GetApi")
let two = PostApi(bar: "PostApi")
let three = PutApi(bar: "PutApi")
let four = DeleteApi(bar: "DeleteApi")
let five = GetDownloadApi(bar: "GetDownloadApi")


batchApi = NetBatchRequest(requests: [one, two, three, four, five])
one.responseJSON { (json, error) -> Void in
    if (error != nil) {
        print("==========error: \(error)")
    } else {
        print("one finished: \(json)")
    }
}

batchApi?.completion = { error in
    if let error = error {
        print("batch request failure : \(error)")
    } else {
        print("batch request success")
    }
}
batchApi?.start()
```
###chain request
```swift
let one = GetApi(bar: "GetApi")
let two = PostApi(bar: "PostApi")
let three = PutApi(bar: "PutApi")
let four = DeleteApi(bar: "DeleteApi")

chainApi = NetChainRequest()
chainApi?.addRequest(one) { (json, error) -> Void in
    print("++++++ 1 finished")
    self.chainApi?.addRequest(two) { (json, error) -> Void in
        print("++++++ 2 finished")
        self.chainApi?.addRequest(three) { (json, error) -> Void in
            print("++++++ 3 finished")
            self.chainApi?.addRequest(four) { (json, error) -> Void in
                print("++++++ 4 finished")
            }
        }
    }
}

chainApi?.completion = { error in
    if let error = error {
        print("chain request failure : \(error)")
    } else {
        print("chain request success")
    }
}
chainApi?.start()
```

##TODO

 * optimize & bug fix
 * more test
 
## License
ETNetwork is released under the MIT license. See LICENSE for details.
