//
//  ETNetworkConfig.swift
//  ETNetwork
//
//  Created by ethan on 15/11/5.
//  Copyright © 2015年 ethan. All rights reserved.
//

import UIKit

class ETNetworkConfig: NSObject {
    class var sharedInstance : ETNetworkConfig {
        struct Static {
            static let instance : ETNetworkConfig = ETNetworkConfig()
        }
        return Static.instance
    }
    
    /*use you own base url*/
    var baseUrl: String = "www.baidu.com"
    var urlFilters: Array<String> = []
    var cacheDirPathFilters: Array<String> = []
}
