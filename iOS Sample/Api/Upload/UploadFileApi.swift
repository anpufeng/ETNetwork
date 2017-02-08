//
//  UploadFileApi.swift
//  iOS Sample
//
//  Created by gengduo on 15/12/18.
//  Copyright © 2015年 ethan. All rights reserved.
//

import UIKit
import ETNetwork

class UploadFileApi: ETRequest {

    var ImgURL: URL
    init(fileURL: URL) {
        self.ImgURL = fileURL
        super.init()
    }
}

extension UploadFileApi: ETRequestProtocol {
    var method: ETRequestMethod { return .post }
    var taskType: ETTaskType { return .uploadFileURL }
    var requestUrl: String { return "/post" }
    var parameters:  [String: AnyObject]? {
        return ["upload": "UploadFileApi" as AnyObject]
    }

    var headers: [String: String]? { return ["UploadFileApi": "UploadFileApiHeader"]  }
}

extension UploadFileApi: ETRequestUploadProtocol {
    var fileURL: URL? { return self.ImgURL }
}

