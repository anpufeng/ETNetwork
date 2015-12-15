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
    var method: ETRequestMethod { return .Post }
    var requestUrl: String { return "/post" }
    var parameters:  [String: AnyObject]? {
        return ["foo": bar]
    }
}

extension PostApi: ETRequestCacheProtocol {
    
    //cache
    var cacheVersion: UInt64 { return 1 }
    var cacheSeconds: Int { return 6 }
}
