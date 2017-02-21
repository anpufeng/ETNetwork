//
//  UploadStreamApi.swift
//  iOS Sample
//
//  Created by gengduo on 15/12/21.
//  Copyright © 2015年 ethan. All rights reserved.
//

import UIKit
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

