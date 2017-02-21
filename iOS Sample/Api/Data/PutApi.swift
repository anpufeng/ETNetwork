//
//  PutApi.swift
//  iOS Sample
//
//  Created by gengduo on 15/12/16.
//  Copyright © 2015年 ethan. All rights reserved.
//

import UIKit
import ETNetwork

class PutApi: NetRequest {
    var bar: String
    init(bar: String) {
        self.bar = bar
        super.init()
    }
}

extension PutApi: RequestProtocol {
    var method: RequestMethod { return .put }
    var taskType: TaskType { return .data }
    var requestURL: String { return "/put" }
    var parameters:  [String: AnyObject]? {
        return ["foo": bar as AnyObject]
    }
}


extension PutApi: RequestCacheProtocol {
    var cacheVersion: UInt64 { return 1 }
    var cacheSeconds: Int { return 60 }
}
