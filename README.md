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
open iOS Sample.xcodeproj, run the sample project
##every request, implement `ETRequestProtocol` 
```swift
class GetApi: ETRequest {
    
    var bar: String
    init(bar: String) {
        self.bar = bar
        super.init()
    }
}

extension GetApi: ETRequestProtocol {
    var method: ETRequestMethod { return .Get }
    var taskType: ETTaskType { return .Data }
    var requestUrl: String { return "/get" }
    var parameters:  [String: AnyObject]? {
        return ["foo": bar]
    }
}
```
###cache the request, implement `ETRequestCacheProtocol` 
```swift
extension GetApi: ETRequestCacheProtocol {
    var cacheVersion: UInt64 { return 1 }
    var cacheSeconds: Int { return 60 }
}

let dataApi = GetApi(bar: "GetApi")
dataApi.start()
dataApi.responseJson({ (json, error) -> Void in
    if (error != nil) {
        print("==========error: \(error)")
    } else {
        print("==========json: \(json)")
    }
})
```

###download request, implement `ETRequestDownloadProtocol`
```swift
extension GetDownloadApi: ETRequestDownloadProtocol {
    
}

extension DownloadResumeDataApi: ETRequestDownloadProtocol {
    func downloadDestination() -> (NSURL, NSHTTPURLResponse) -> NSURL {
        return { temporaryURL, response -> NSURL in
            let directoryURLs = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
            if !directoryURLs.isEmpty {
                return directoryURLs[0].URLByAppendingPathComponent("mydownload.dmg")
            }
            
            return temporaryURL
        }
    }
    
    var resumeData: NSData? { return data }
}
```
###upload request, implement `ETRequestUploadProtocol`
```swift
extension UploadStreamApi: ETRequestUploadProtocol {
    var formData: [UploadFormProtocol]? {
        var forms: [UploadFormProtocol] = []
        let jsonInputStream = NSInputStream(data: jsonData)
        let jsonStreamWrap = UploadFormStream(name: "streamJson", stream: jsonInputStream, length: UInt64(jsonData.length), fileName: "streamJsonFileName", mimeType: "text/plain")

        let imgInputStream = NSInputStream(data: imgData)
        let imgStreamWrap = UploadFormStream(name: "streamImg", stream: imgInputStream, length: UInt64(imgData.length), fileName: "steamImgFileName", mimeType: "image/png")

        forms.append(jsonStreamWrap)
        forms.append(imgStreamWrap)

        let dataPath = NSBundle.mainBundle().pathForResource("test", ofType: "txt")
        if let dataPath = dataPath {
            if let data = NSData(contentsOfFile: dataPath) {
                let dataForm = UploadFormData(name: "testtxt", data: data)
                forms.append(dataForm)
            }
        }

        let fileURL = NSBundle.mainBundle().URLForResource("upload2", withExtension: "png")
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
uploadApi.formDataencodingError { (error) -> Void in
            print("encoding error: \(error)")
        }.progress({ (bytesWrite, totalBytesWrite, totalBytesExpectedToWrite) -> Void in
            //print("bytesWrite: \(bytesWrite), totalBytesWrite: \(totalBytesWrite), totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
            print("percent: \(100 * Double(totalBytesWrite)/Double(totalBytesExpectedToWrite))")
        })
```
###batch request
```swift
let one = GetApi(bar: "GetApi")
let two = PostApi(bar: "PostApi")
let three = PutApi(bar: "PutApi")
let four = DeleteApi(bar: "DeleteApi")
let five = GetDownloadApi(bar: "GetDownloadApi")


batchApi = ETBatchRequest(requests: [one, two, three, four, five])
batchApi?.start()
```
###chain request
```swift
let one = GetApi(bar: "GetApi")
let two = PostApi(bar: "PostApi")
let three = PutApi(bar: "PutApi")
let four = DeleteApi(bar: "DeleteApi")

chainApi = ETChainRequest()
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
```

##TODO

 * optimize & bug fix
 * more test
 
## License
ETNetwork is released under the MIT license. See LICENSE for details.
