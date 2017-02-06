//
//  GetApi.swift
//  iOS Sample
//
//  Created by ethan on 15/11/18.
//  Copyright © 2015年 ethan. All rights reserved.
//

import UIKit
import ETNetwork

class GetDownloadApi: ETRequest {
    
    var bar: String
    init(bar: String) {
        self.bar = bar
        super.init()
    }
}

extension GetDownloadApi: ETRequestProtocol {
    var method: ETRequestMethod { return .get }
    var taskType: ETTaskType { return .download }
    var requestUrl: String { return "http://dldir1.qq.com/qqfile/QQforMac/QQ_V4.0.6.dmg" }
    var parameters:  [String: AnyObject]? {
        return nil
    }
}


extension GetDownloadApi: ETRequestCacheProtocol {
    
    //cache
    var cacheSeconds: Int { return -1 }
}

extension GetDownloadApi: ETRequestDownloadProtocol {
    
}

