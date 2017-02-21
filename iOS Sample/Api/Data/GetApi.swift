//
//  GetApi.swift
//  iOS Sample
//
//  Created by ethan on 15/11/18.
//  Copyright © 2015年 ethan. All rights reserved.
//

import UIKit
import ETNetwork

class GetApi: NetRequest {
    
    var bar: String
    init(bar: String) {
        self.bar = bar
        super.init()
    }
}

extension GetApi: RequestProtocol {
    var method: RequestMethod { return .get }
    var taskType: TaskType { return .data }
    var requestURL: String { return "/get" }
    var parameters:  [String: AnyObject]? {
        return ["foo": bar as AnyObject]
    }
}


extension GetApi: RequestCacheProtocol {
    var cacheVersion: UInt64 { return 1 }
    var cacheSeconds: Int { return 60 }
}

