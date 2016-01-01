# ETNetwork
## What

ETNetwork is is a high level request util based on [Alamofire](https://github.com/Alamofire/Alamofire), take [YTKNetwork](https://github.com/yuantiku/YTKNetwork/) as reference. 
## Features

## Why using CryptoSwift
because using md5 in swift is complicated. http://iosdeveloperzone.com/2014/10/03/using-commoncrypto-in-swift/ , and I don't want to impor Obj-c file. CryptoSwift is good.
## How to use
open iOS Sample.xcodeproj, you will see the sample api

```bash
$ git clone https://github.com/anpufeng/ETNetwork/
```
for example: 
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

for more detail, please run the demo project

##TODO
 * batch request
 * chain request
 * do we need request delegate?
 * optimize & bug fix
