//
//  ETBaseRequest.swift
//  ETNetwork
//
//  Created by ethan on 15/11/4.
//  Copyright © 2015年 ethan. All rights reserved.
//

import Foundation

public enum ETRequestMethod {
    case Options, Get, Head, Post, Put, Patch, Delete, Trace, Connect
    
    var method: Method {
        switch self {
        case .Options:
            return Method.OPTIONS
        case .Get:
            return Method.GET
        case .Head:
            return Method.HEAD
        case .Post:
            return Method.POST
        case .Put:
            return Method.PUT
        case .Patch:
            return Method.PATCH
        case .Delete:
            return Method.DELETE
        case .Trace:
            return Method.TRACE
        case .Connect:
            return Method.CONNECT

        }
    }
}

public enum ETRequestParameterEncoding {
    case Url
    case UrlEncodedInURL
    case Json
    case PropertyList(NSPropertyListFormat, NSPropertyListWriteOptions)
    
    var encode: ParameterEncoding {
        switch self {
        case .Url:
            return ParameterEncoding.URL
        case .UrlEncodedInURL:
            return ParameterEncoding.URLEncodedInURL
        case .Json:
            return ParameterEncoding.JSON
        case .PropertyList(let format, let options):
            return ParameterEncoding.PropertyList(format, options)
        }
    }
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
    func requestUrl() -> String
    
    func baseUrl() -> String
    func requestMethod() -> ETRequestMethod
    func requestParams() ->  [String: AnyObject]?
    func requestSerializer() -> ETRequestSerializer
    func requestTimeout() -> NSTimeInterval
    func requestHeaders() -> [String: String]?
    func requestParameterEncoding() -> ETRequestParameterEncoding
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
    
    func requestTimeout() -> NSTimeInterval {
        //default twenty seconds
        return 20
    }
    
    func requestHeaders() -> [String: String]? {
        return nil
    }
}


class ETBaseRequest: NSObject {
    weak internal var delegate: ETRequestDelegate?
    private var request: Request?
    var manager: ETManager
    private var tag: Int = 0
    var responseString: String?
    var responseData: String?
    var responseJson: AnyObject?
    
    deinit {
        print("ETBaseRequest  deinit")
    }
    func start() -> Void {
        ETManager.sharedInstance.addRequest(self)
    }
    
    func startWithManager(manager: ETManager) {
        manager.addRequest(self)
    }
    
    
    func stop() -> Void {
        
    }
    
    override init() {
        manager = ETManager.init()
        super.init()
    }
    func isExecuting() -> Bool {
        return false;
    }
    
    
    func requestWithManage(manager: ETManager) -> Void {
        
    }   
}
