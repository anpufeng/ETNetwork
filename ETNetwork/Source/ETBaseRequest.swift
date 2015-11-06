//
//  ETBaseRequest.swift
//  ETNetwork
//
//  Created by ethan on 15/11/4.
//  Copyright © 2015年 ethan. All rights reserved.
//

import Foundation

enum ETRequestMethod: Int {
    case Get
    case Post
    case Head
    case Put
    case Delete
    case Patch
}

/*
delegate callback
*/
@objc protocol ETRequestDelegate {
    optional func requestFinished(request: ETBaseRequest)
    optional func requestFailed(request: ETBaseRequest)
}

/*
custom your own request, all custom
*/
protocol ETBuildCustomRequest {
    func customUrlRequest() -> NSURLRequest
}

/*
allow cache your request response data
*/
protocol ETCache {
    func cacheSeconds() -> Int
}

/*
you detail url to request eg http://www.google.com/api/query | api/query
*/


protocol ETRequestUrl {
    func requestUrl() -> String
}

/*
you detail url to request
*/
 protocol ETBaseRequestProtocol : class {
    func baseUrl() -> String
    func requestUrl() -> String
    func requestMethod() -> ETRequestMethod
    func requestParams() ->  [String: AnyObject]?
    
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
    func start() {
        
    }
    
    func start(completion: () -> ()))
    
    func stop() {
        
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
