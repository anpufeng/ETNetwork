//
//  PutApi.swift
//  iOS Sample
//
//  Created by gengduo on 15/12/16.
//  Copyright © 2015年 ethan. All rights reserved.
//

import UIKit
import ETNetwork

class DeleteApi: ETRequest {


    var bar: String
    init(bar: String) {
        self.bar = bar
        super.init()
    }
}

extension DeleteApi: ETRequestProtocol {
    var method: ETRequestMethod { return .delete }
    var taskType: ETTaskType { return .data }
    var requestUrl: String { return "/delete" }
    var parameters:  [String: AnyObject]? {
        return ["foo": bar as AnyObject]
    }
}


extension DeleteApi: ETRequestCacheProtocol {
    var cacheVersion: UInt64 { return 1 }
    var cacheSeconds: Int { return 60 }
}
