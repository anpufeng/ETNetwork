//
//  ETBaseRequest.swift
//  ETNetwork
//
//  Created by ethan on 15/11/4.
//  Copyright © 2015年 ethan. All rights reserved.
//

import Foundation

enum ETRequestMethod: String {
    case Options, Get, Head, Post, Put, Patch, Delete, Trace, Connect
}

enum ETRequestSerializer {
    case Data, String, Json
}

/**
 delegate callback
*/
@objc protocol ETRequestDelegate {
    optional func requestFinished(request: ETBaseRequest)
    optional func requestFailed(request: ETBaseRequest)
}

/**
 custom your own request, all custom
*/
protocol ETBuildCustomRequest {
    func customUrlRequest() -> NSURLRequest
}

/**
 allow cache your request response data
*/
protocol ETCache {
    func cacheSeconds() -> Int
}


/**
 you detail url to request
*/
 protocol ETBaseRequestProtocol : class {
    func baseUrl() -> String
    func requestUrl() -> String
    func requestMethod() -> ETRequestMethod
    func requestParams() ->  [String: AnyObject]?
    func requestSerializer() -> ETRequestSerializer
}

/**
 make it optional
*/
extension ETBaseRequestProtocol {
    func baseUrl() -> String {
        return ETNetworkConfig.sharedInstance.baseUrl
    }
    
    func requestParams() ->  [String: AnyObject]? {
        return nil
    }
    
    func requestSerializer() -> ETRequestSerializer {
        return .Json
    }
    
    func requestMethod() -> ETRequestMethod {
        return .Post
    }
}


class ETBaseRequest: NSObject {
    weak var child: ETBaseRequestProtocol?
    weak private var delegate: ETRequestDelegate?
    private var request: Request?
    var manager: ETManager
    private var tag: Int = 0
    
    deinit {
        print("ETBaseRequest  deinit")
    }
    func start() -> Void {
        
    }
    
    
    func stop() -> Void {
        
    }
    
    override init() {
        manager = ETManager.init()
        super.init()

        if let sub = self as? ETBaseRequestProtocol {
            child = sub
        } else {
            fatalError("must conform ETBaseRequestProtocol")
        }
    }
    func isExecuting() -> Bool {
        return false;
    }
    
    
    func requestWithManage(manager: ETManager) -> Void {
        
    }

    
   
}
