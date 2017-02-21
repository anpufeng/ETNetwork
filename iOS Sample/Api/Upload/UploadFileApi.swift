//
//  UploadFileApi.swift
//  iOS Sample
//
//  Created by gengduo on 15/12/18.
//  Copyright © 2015年 ethan. All rights reserved.
//

import UIKit
import ETNetwork

class UploadFileApi: NetRequest {

    var ImgURL: URL
    init(fileURL: URL) {
        self.ImgURL = fileURL
        super.init()
    }
}

extension UploadFileApi: RequestProtocol {
    var method: RequestMethod { return .post }
    var taskType: TaskType { return .uploadFileURL }
    var requestURL: String { return "/post" }
    var parameters:  [String: AnyObject]? {
        return ["upload": "UploadFileApi" as AnyObject]
    }

    var headers: [String: String]? { return ["UploadFileApi": "UploadFileApiHeader"]  }
}

extension UploadFileApi: RequestUploadProtocol {
    var fileURL: URL? { return self.ImgURL }
}

