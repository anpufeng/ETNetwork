//
//  UploadStreamApi.swift
//  iOS Sample
//
//  Created by gengduo on 15/12/21.
//  Copyright © 2015年 ethan. All rights reserved.
//

import UIKit
import ETNetwork

class UploadStreamApi: ETRequest {

    var jsonData: NSData
    var imgData: NSData
    init(jsonData : NSData, imgData: NSData) {
        self.jsonData = jsonData
        self.imgData = imgData
        super.init()
    }
}

extension UploadStreamApi: ETRequestProtocol {
    var method: ETRequestMethod { return .Post }
    var taskType: TaskType { return .Upload }
    var requestUrl: String { return "/post" }
    var parameters:  [String: AnyObject]? {
        return ["upload": "UploadStreamApiParameters"]
    }

    var headers: [String: String]? { return ["UploadDataApi": "UploadDataApiHeader"]  }
}


extension UploadStreamApi: ETRequestCacheProtocol {

    //cache
    var cacheSeconds: Int { return 0 }
}

extension UploadStreamApi: ETREquestUploadProtocol {
    var uploadType: UploadType { return .FormData }
    var fileURL: NSURL? { return nil }
    var fileData: NSData? { return nil }
    var formData: [UploadWrap]? {
        var forms: [UploadWrap] = []
        let jsonInputStream = NSInputStream(data: jsonData)
        let jsonStreamWrap = UploadWrapStream(name: "streamJson", stream: jsonInputStream, length: UInt64(jsonData.length), fileName: "streamJsonFileName", mimeType: "text/plain")

        let imgInputStream = NSInputStream(data: imgData)
        let imgStreamWrap = UploadWrapStream(name: "streamImg", stream: imgInputStream, length: UInt64(jsonData.length), fileName: "steamImgFileName", mimeType: "image/png")

        forms.append(jsonStreamWrap)
        forms.append(imgStreamWrap)

        let dataPath = NSBundle.mainBundle().pathForResource("test", ofType: "txt")
        if let dataPath = dataPath {
            if let data = NSData(contentsOfFile: dataPath) {
                let dataForm = UploadWrapData(name: "testtxt", data: data)
                forms.append(dataForm)
            }
        }

        let fileURL = NSBundle.mainBundle().URLForResource("upload2", withExtension: "png")
        if let fileURL = fileURL {
            let fileWrap = UploadWrapFileURL(name: "upload2png", fileURL: fileURL)
            forms.append(fileWrap)
        }

        return forms
    }
}

