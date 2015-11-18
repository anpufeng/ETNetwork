//
//  GetApi.swift
//  iOS Sample
//
//  Created by ethan on 15/11/18.
//  Copyright © 2015年 ethan. All rights reserved.
//

import UIKit
import ETNetwork

class GetApi: ETBaseRequest, ETBaseRequestProtocol {
    
    var bar: String
    init(bar: String) {
        self.bar = bar
        super.init()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func requestUrl() -> String {
        return "/get"
    }
    
    
    func requestParams() ->  [String: AnyObject]? {
        return  ["foo": bar]
    }

}
