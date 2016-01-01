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

    var ImgURL: NSURL
    init(fileURL: NSURL) {
        self.ImgURL = fileURL
        super.init()
    }
}

extension UploadFileApi: ETRequestProtocol {
    var method: ETRequestMethod { return .Post }
    var taskType: TaskType { return .Upload }
    var requestUrl: String { return "/post" }
    var parameters:  [String: AnyObject]? {
        return ["upload": "UploadFileApi"]
    }

    var headers: [String: String]? { return ["UploadFileApi": "UploadFileApiHeader"]  }
}


extension UploadFileApi: ETRequestCacheProtocol {

    //cache
    var cacheSeconds: Int { return 0 }
}

extension UploadFileApi: ETRequestUploadProtocol {
    var uploadType: UploadType { return .FileURL }
    var fileURL: NSURL? { return self.ImgURL }
}

