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
    var taskType: ETTaskType { return .UploadFormData }
    var requestUrl: String { return "/post" }
    var parameters:  [String: AnyObject]? {
        return ["upload": "UploadStreamApiParameters"]
    }

    var headers: [String: String]? { return ["UploadDataApi": "UploadDataApiHeader"]  }
}

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

