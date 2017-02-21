//
//  NetConfig.swift
//  ETNetwork
//
//  Created by ethan on 15/11/5.
//  Copyright © 2015年 ethan. All rights reserved.
//

import UIKit

open class NetConfig {
     open static let sharedInstance: NetConfig = {
        
        return NetConfig()
    }()
    
    /*use you own base url*/
    var baseURL: String = "https://httpbin.org"
    var urlFilters: Array<String> = []
    var cacheDirPathFilters: Array<String> = []
}
