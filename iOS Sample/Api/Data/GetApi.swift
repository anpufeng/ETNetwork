//
//  GetApi.swift
//  iOS Sample
//
//  Created by ethan on 15/11/18.
//  Copyright © 2015年 ethan. All rights reserved.
//

import UIKit
import ETNetwork

class GetApi: ETRequest {
    
    var bar: String
    init(bar: String) {
        self.bar = bar
        super.init()
    }
}

extension GetApi: ETRequestProtocol {
    var method: ETRequestMethod { return .Get }
    var taskType: ETTaskType { return .Data }
    var requestUrl: String { return "/get" }
    var parameters:  [String: AnyObject]? {
        return ["foo": bar]
    }
}


extension GetApi: ETRequestCacheProtocol {
    var cacheVersion: UInt64 { return 1 }
    var cacheSeconds: Int { return 60 }
}

