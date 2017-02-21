//
//  UploadFileApi.swift
//  iOS Sample
//
//  Created by gengduo on 15/12/18.
//  Copyright © 2015年 ethan. All rights reserved.
//

import UIKit
import ETNetwork

class UploadDataApi: NetRequest {

    var data: Data
    init(data : Data) {
        self.data = data
        super.init()
    }
}

extension UploadDataApi: RequestProtocol {
    var method: RequestMethod { return .post }
    var taskType: TaskType { return .uploadFileData }
    var requestURL: String { return "/post" }
    var parameters:  [String: AnyObject]? {
        return ["upload": "UploadDataApi" as AnyObject]
    }

    var headers: [String: String]? { return ["UploadDataApi": "UploadDataApiHeader"]  }
}

extension UploadDataApi: RequestUploadProtocol {
    var fileData: Data? { return data }
}

