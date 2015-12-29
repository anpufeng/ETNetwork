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
        let jsonInputStream = NSInputStream(data: jsonData)
        let jsonStream = UploadWrapStream(name: "streamName", stream: jsonInputStream, length: UInt64(jsonData.length), fileName: "streamFileName", mimeType: "text/plain")

        let imgInputStream = NSInputStream(data: imgData)
        let imgStream = UploadWrapStream(name: "streamName", stream: imgInputStream, length: UInt64(jsonData.length), fileName: "streamFileName", mimeType: "image/png")


        return [jsonStream, imgStream]
    }
}

