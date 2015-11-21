//
//  ETBaseRequest.swift
//  ETNetwork
//
//  Created by ethan on 15/11/4.
//  Copyright © 2015年 ethan. All rights reserved.
//

import Foundation
import CryptoSwift

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


public enum ETResponseSerializer {
    case Data, String, Json, PropertyList
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
protocol ETRequestCustom {
    func customUrlRequest() -> NSURLRequest
}

/**
 allow cache your request response data
*/
public protocol ETRequestCacheProtocol: class {
    func cacheSeconds() -> Int
    func cacheDataType() -> ETResponseSerializer
}

public extension ETRequestCacheProtocol {
    
    func cacheDataType() -> ETResponseSerializer {
        return .Data
    }
}

/**
 you detail url to request
*/
 public protocol ETBaseRequestProtocol : class {
    func requestUrl() -> String
    
    func baseUrl() -> String
    func requestMethod() -> ETRequestMethod
    func requestParams() ->  [String: AnyObject]?
    func requestSerializer() -> ETResponseSerializer
    func requestTimeout() -> NSTimeInterval
    func requestHeaders() -> [String: String]?
    func requestParameterEncoding() -> ETRequestParameterEncoding
    func requestResponseStringEncoding() -> NSStringEncoding?
    func requestResponseJsonReadingOpion() -> NSJSONReadingOptions
}

/**
 make ETBaseRequestProtocol default and optional
*/
public extension ETBaseRequestProtocol {
    func baseUrl() -> String {
        return ETNetworkConfig.sharedInstance.baseUrl
    }
    
    func requestParams() ->  [String: AnyObject]? {
        return nil
    }
    
    func requestSerializer() -> ETResponseSerializer {
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
    
    func requestResponseStringEncoding() -> NSStringEncoding? {
        return nil
    }
    
    func requestResponseJsonReadingOpion() -> NSJSONReadingOptions {
        return .AllowFragments
    }
}


public class ETBaseRequest {
    public weak var delegate: ETRequestDelegate?
    
    var request: Request?

//    var resStr: String?
//    var resJson: AnyObject?
//    var resError: NSError?
    
    public var ignoreCache: Bool = true
    public var dataFromCache: Bool = false
    public var dataCached: Bool = false
    
    deinit {
        print("ETBaseRequest  deinit")
    }
    public func start() -> Void {
        if self.shouldUseCache() {
            return
        }
        
        ETManager.sharedInstance.addRequest(self)
    }
    
    public func startWithManager(manager: ETManager) {
        if self.shouldUseCache() {
            return
        }
        
        manager.addRequest(self)
    }
    
    
    public func cancel() -> Void {
        self.request?.cancel()
    }
    
    private func startRequest() -> Void {
        ETManager.sharedInstance.addRequest(self)
    }
    
    
    public init() {
    }
    

//    public func isExecuting() -> Bool {
//        return false;
//    }
    
    
    public func requestWithManage(manager: ETManager) -> Void {
        self.startRequest()
    }   
}


public extension ETBaseRequest {
//    public var responseJson: AnyObject? {
//        if let _ = resError {
//            return nil
//        }
//        
//        return resJson
//    }
//    
//    public var responseStr: String? {
//        if let _ = resError {
//            return nil
//        }
//        
//        return resStr
//    }
//    
//    public var responseData: NSData? {
//        if let _ = resError {
//            return nil
//        }
//        
//        return self.request?.delegate.data
//    }
//    
//    public var responseError: NSError? {
//        return resError
//    }
    
    public var responseAllHeaders: [NSObject : AnyObject]? {
        return self.request?.response?.allHeaderFields
    }
    
    public func responseStr(completion: (String?, NSError?) -> Void ) -> Self {
        self.request?.responseString(completionHandler: { response -> Void in
            completion(response.result.value, response.result.error)
        })
        return self
    }
    
    public func responseJson(completion: (AnyObject?, NSError?) -> Void ) -> Self {
        var jsonOption: NSJSONReadingOptions = .AllowFragments
        if let subRequest = self as? ETBaseRequestProtocol {
            jsonOption = subRequest.requestResponseJsonReadingOpion()
        }
        self.request?.responseJSON(options: jsonOption, completionHandler: { response -> Void in
            try? self.saveResponseToCacheFile()
            completion(response.result.value, response.result.error)
        })
        return self
    }
    
    public func responseData(completion: (NSData?, NSError?) -> Void ) -> Self {
        self.request?.responseData({ response -> Void in
            completion(response.result.value, response.result.error)
        })
        return self
    }
    
}

//MARK: cache
public extension ETBaseRequest {
    private func shouldUseCache() -> Bool {
        if ignoreCache {
            return false
        }
        
        guard let cacheProtocol = self as? ETRequestCacheProtocol else { return false }
        
        if cacheProtocol.cacheSeconds() < 0 {
            return false
        }

//        guard let cacheFilePath = self.cacheFilePath() else { return false }
        if !NSFileManager.defaultManager().fileExistsAtPath(self.cacheFilePath()) {
            return false
        }
        
        return true
    }
    
    private func shouldStoreCache() -> Bool {
        if dataFromCache {
            return false
        }
        
        guard let cacheProtocol = self as? ETRequestCacheProtocol else { return false }
        if cacheProtocol.cacheSeconds() < 0 {
            return false
        }
        
        
        return true
    }
    
    private func saveResponseToCacheFile() throws -> Void {
        guard let cacheProtocol = self as? ETRequestCacheProtocol else { return }
        //only cache data
        guard let data = self.request?.delegate.data else { return }
        
        switch cacheProtocol.cacheDataType() {
        default:
//            let result = data.writeToFile(self.cacheFilePath(), atomically: true)
            NSKeyedArchiver.archiveRootObject(data, toFile: self.cacheFilePath())
            //print("write to file: \(self.cacheFilePath()) result: \(result)")
        }
    }
    private func cacheFilePath() -> String {
        let fullPath = "\(self.cacheBasePath())/\(self.cacheFileName())"
        print(fullPath)
        return fullPath
    }
    
    private func cacheFileName() -> String {
        guard let request = self as? ETBaseRequestProtocol else { fatalError("must implement ETBaseRequestProtocol")}
        let requestUrl = request.requestUrl()
        let baseUrl = request.baseUrl()
        let params = request.requestParams()
        
        let requestInfo = "Method:\(request.requestMethod()) Host:\(baseUrl) Url:\(requestUrl) Param:\(params), AppVersion\(ETBaseRequest.appVersion)"
        let md5 = requestInfo.md5()
        print("filename md5: \(md5)")
        
        return md5
    }
    
    
    private func cacheBasePath() -> String {
        let libraryPaths = NSSearchPathForDirectoriesInDomains(.LibraryDirectory, .UserDomainMask, true)
        return libraryPaths[0]
    }
    
    public static var appVersion: String {
        let nsObject: AnyObject? = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"]
        let version = nsObject as! String
        return version
    }
}
