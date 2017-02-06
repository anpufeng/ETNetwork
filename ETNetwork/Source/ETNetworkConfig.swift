//
//  ETNetworkConfig.swift
//  ETNetwork
//
//  Created by ethan on 15/11/5.
//  Copyright © 2015年 ethan. All rights reserved.
//

import UIKit

open class ETNetworkConfig {
     open static let sharedInstance: ETNetworkConfig = {
        
        return ETNetworkConfig()
    }()
    
    /*use you own base url*/
    var baseUrl: String = "https://httpbin.org"
    var urlFilters: Array<String> = []
    var cacheDirPathFilters: Array<String> = []
}
