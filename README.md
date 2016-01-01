# ETNetwork
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
```
open iOS Sample.xcodeproj, you will see the sample api
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
    var requestUrl: String { return "/get" }
    var parameters:  [String: AnyObject]? {
        return ["foo": bar]
    }
}
```
###cache the request
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

###download request, 
```swift
extension GetDownloadApi: ETRequestDownloadProtocol {
    
}
```
###upload request
```swift
extension UploadStreamApi: ETRequestUploadProtocol {
    var uploadType: UploadType { return .FormData }
    var formData: [UploadFormProtocol]? {
        var forms: [UploadFormProtocol] = []
        let jsonInputStream = NSInputStream(data: jsonData)
        let jsonStreamWrap = UploadFormStream(name: "streamJson", stream: jsonInputStream, length: UInt64(jsonData.length), fileName: "streamJsonFileName", mimeType: "text/plain")

        let imgInputStream = NSInputStream(data: imgData)
        let imgStreamWrap = UploadFormStream(name: "streamImg", stream: imgInputStream, length: UInt64(jsonData.length), fileName: "steamImgFileName", mimeType: "image/png")

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



##TODO
 * batch request
 * chain request
 * do we need request delegate?
 * optimize & bug fix
