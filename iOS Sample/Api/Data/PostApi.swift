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
class PostApi: NetRequest {
    
    var bar: String
    init(bar: String) {
        self.bar = bar
        super.init()
    }
}

extension PostApi: RequestProtocol {
    var headers: [String: String]? {
        return ["token": "YourCustomToken"]
    }
    var method: RequestMethod { return .post }
    var taskType: TaskType { return .data }
    var requestURL: String { return "/post" }
    var parameters:  [String: Any]? {
        return ["foo": bar]
    }
}

extension PostApi: RequestCacheProtocol {
    var cacheVersion: UInt64 { return 1 }
    var cacheSeconds: Int { return 60 }
}
