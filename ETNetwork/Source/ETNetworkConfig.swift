//
//  ETNetworkConfig.swift
//  ETNetwork
//
//  Created by ethan on 15/11/5.
//  Copyright © 2015年 ethan. All rights reserved.
//

import UIKit

public class ETNetworkConfig: NSObject {
     public static let sharedInstance: ETNetworkConfig = {
        
        return ETNetworkConfig()
    }()
    
    /*use you own base url*/
    var baseUrl: String = "www.baidu.com"
    var urlFilters: Array<String> = []
    var cacheDirPathFilters: Array<String> = []
}
