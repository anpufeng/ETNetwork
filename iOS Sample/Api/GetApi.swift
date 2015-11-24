//
//  GetApi.swift
//  iOS Sample
//
//  Created by ethan on 15/11/18.
//  Copyright © 2015年 ethan. All rights reserved.
//

import UIKit
import ETNetwork

class GetApi: ETRequest, ETRequestProtocol, ETRequestCacheProtocol {
    
    var bar: String
    init(bar: String) {
        self.bar = bar
        super.init()
    }
    
    
    var method: ETRequestMethod { return .Get }
    
    var requestUrl: String { return "/get" }
    
    var parameters:  [String: AnyObject]? {
        return ["foo": bar]
    }
    
    var cacheVersion: UInt64 { return 0 }
    var cacheSeconds: Int { return 120 }
}
