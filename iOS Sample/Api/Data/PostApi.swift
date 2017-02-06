//
//  PostApi.swift
//  iOS Sample
//
//  Created by ethan on 15/11/29.
//  Copyright © 2015年 ethan. All rights reserved.
//

import UIKit
import ETNetwork


/// PostApi with custom headers
class PostApi: ETRequest {
    
    var bar: String
    init(bar: String) {
        self.bar = bar
        super.init()
    }
}

extension PostApi: ETRequestProtocol {
    var headers: [String: String]? {
        return ["token": "YourCustomToken"]
    }
    var method: ETRequestMethod { return .post }
    var taskType: ETTaskType { return .data }
    var requestUrl: String { return "/post" }
    var parameters:  [String: AnyObject]? {
        return ["foo": bar as AnyObject]
    }
}

extension PostApi: ETRequestCacheProtocol {
    var cacheVersion: UInt64 { return 1 }
    var cacheSeconds: Int { return 60 }
}
