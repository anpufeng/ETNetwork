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
    var method: ETRequestMethod { return .Get }
    var requestUrl: String { return "http://download.thinkbroadband.com/10MB.zip" }
    var parameters:  [String: AnyObject]? {
        return nil
    }
}


extension GetDownloadApi: ETRequestCacheProtocol {
    
    //cache
    var cacheSeconds: Int { return 0 }
}

extension GetDownloadApi: ETRequestDownloadProtocol {
    
}

