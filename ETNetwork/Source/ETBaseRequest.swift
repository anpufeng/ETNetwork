//
//  ETBaseRequest.swift
//  ETNetwork
//
//  Created by ethan on 15/11/4.
//  Copyright © 2015年 ethan. All rights reserved.
//

import Foundation


protocol ETRequestDelegate {
    
    optional func requestFinished(request: ETBaseRequest)
    optional func requestFailed(request: ETBaseRequest)
    
}

protocol CacheProtocol {
    func cacheSeconds() -> Int
}

class ETBaseRequest: NSObject {
//    private var request: Request

}
