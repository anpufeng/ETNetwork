//
//  UploadFileApi.swift
//  iOS Sample
//
//  Created by gengduo on 15/12/18.
//  Copyright © 2015年 ethan. All rights reserved.
//

import UIKit
import ETNetwork

class UploadDataApi: ETRequest {

    var data: NSData
    init(data : NSData) {
        self.data = data
        super.init()
    }
}

extension UploadDataApi: ETRequestProtocol {
    var method: ETRequestMethod { return .Post }
    var taskType: TaskType { return .Upload }
    var requestUrl: String { return "/post" }
    var parameters:  [String: AnyObject]? {
        return ["upload": "UploadDataApi"]
    }

    var headers: [String: String]? { return ["UploadDataApi": "UploadDataApiHeader"]  }
}

extension UploadDataApi: ETRequestUploadProtocol {
    var uploadType: UploadType { return .FileData }
    var fileURL: NSURL? { return nil }
    var fileData: NSData? { return data }
    var formData: [UploadFormProtocol]? { return nil }
}

