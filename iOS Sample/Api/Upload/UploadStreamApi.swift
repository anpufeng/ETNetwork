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

    var data: NSData
    init(data : NSData) {
        self.data = data
        super.init()
    }
}

extension UploadStreamApi: ETRequestProtocol {
    var method: ETRequestMethod { return .Post }
    var taskType: TaskType { return .Upload }
    var requestUrl: String { return "/post" }
    var parameters:  [String: AnyObject]? {
        return ["upload": "UploadStreamApi"]
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
        let inputStream = NSInputStream(data: data)
        let stream = UploadWrapStream(name: "streamName", fileName: "streamFilename", mimeType: "", stream: inputStream, length: UInt64(data.length))

        return [stream]
    }
}

