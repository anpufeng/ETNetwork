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


public enum ETRequestSerializer {
    case Data, String, Json
}

//public enum ETResponse {
//    case Json(AnyObject, NSError)
//    case Data(NSDate, NSError)
//    case str(String, NSError)
//}

/**
 delegate callback
*/
public protocol ETRequestDelegate : class {
    func requestFinished(request: ETBaseRequest)
    func requestFailed(request: ETBaseRequest)
}

/**
 make it optional
*/
public  extension ETRequestDelegate {
    func requestFinished(request: ETBaseRequest) {
        
    }
    func requestFailed(request: ETBaseRequest) {
        
    }
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
 public protocol ETBaseRequestProtocol : class {
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
 make it default and optional
*/
public extension ETBaseRequestProtocol {
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
    
    func requestParameterEncoding() -> ETRequestParameterEncoding {
        return .Json
    }
}


public class ETBaseRequest {
    public weak var delegate: ETRequestDelegate?
    
    var request: Request?

    var resStr: String?
    var resJson: AnyObject?
    var resError: NSError?
    
    
    
    deinit {
        print("ETBaseRequest  deinit")
    }
    public func start() -> Void {
        ETManager.sharedInstance.addRequest(self)
    }
    
    public func startWithManager(manager: ETManager) {
        manager.addRequest(self)
    }
    
    
    public func stop() -> Void {
        
    }
    
    
    public init() {
    }

    public func isExecuting() -> Bool {
        return false;
    }
    
    
    public func requestWithManage(manager: ETManager) -> Void {
        
    }   
}


public extension ETBaseRequest {
    public var responseJson: AnyObject? {
        if let _ = resError {
            return nil
        }
        
        return resJson
    }
    
    public var responseStr: AnyObject? {
        if let _ = resError {
            return nil
        }
        
        return resStr
    }
    
    public var responseData: AnyObject? {
        if let _ = resError {
            return nil
        }
        
        return self.request?.delegate.data
    }
    
    public var responseAllHeaders: [NSObject : AnyObject]? {
        return self.request?.response?.allHeaderFields
    }
}

public extension ETBaseRequest {

}
