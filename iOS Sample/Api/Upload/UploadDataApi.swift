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

    var data: Data
    init(data : Data) {
        self.data = data
        super.init()
    }
}

extension UploadDataApi: ETRequestProtocol {
    var method: ETRequestMethod { return .post }
    var taskType: ETTaskType { return .uploadFileData }
    var requestUrl: String { return "/post" }
    var parameters:  [String: AnyObject]? {
        return ["upload": "UploadDataApi" as AnyObject]
    }

    var headers: [String: String]? { return ["UploadDataApi": "UploadDataApiHeader"]  }
}

extension UploadDataApi: ETRequestUploadProtocol {
    var fileData: Data? { return data }
}

