//
//  ETRequest.swift
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
    func requestFinished(request: ETRequest)
    func requestFailed(request: ETRequest)
}

/**
 make it optional
*/
public  extension ETRequestDelegate {
    func requestFinished(request: ETRequest) {
        
    }
    func requestFailed(request: ETRequest) {
        
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
 public protocol ETRequestProtocol : class {
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
 make ETRequestProtocol default and optional
*/
public extension ETRequestProtocol {
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


public class ETRequest {
    public weak var delegate: ETRequestDelegate?
    
    var request: Request?
    
    public var ignoreCache: Bool = false
    var dataFromCache: Bool = false
    var dataCached: Bool = false
    var cacheData: NSData?
    
    deinit {
        print("ETRequest  deinit")
    }
    public func start(manager: ETManager = ETManager.sharedInstance, ignoreCache: Bool = false) -> Void {
        self.ignoreCache = ignoreCache
        if self.shouldUseCache() {
            self.delegate?.requestFinished(self)
            return
        }
        
        manager.addRequest(self)
    }
    
    public func cancel() -> Void {
        self.request?.cancel()
    }
    
    
    public init() {
    }
}


public extension ETRequest {

    public var responseAllHeaders: [NSObject : AnyObject]? {
        return self.request?.response?.allHeaderFields
    }
    
    public func responseStr(completion: (String?, NSError?) -> Void ) -> Self {
        if let data = self.cacheData {
            let responseSerializer = Request.stringResponseSerializer(encoding: NSUTF8StringEncoding)
            let result = responseSerializer.serializeResponse(
                self.request?.request,
                self.request?.response,
                data,
                nil
            )
            completion(result.value, result.error)
        } else {
            guard let request = self.request else {
                completion(nil, Error.errorWithCode(-6008, failureReason: "no request"))
                return self
            }
            
            request.responseString(completionHandler: { response -> Void in
                self.saveResponseToCacheFile()
                completion(response.result.value, response.result.error)
            })
        }
        
        return self
    }
    
    public func responseJson(completion: (AnyObject?, NSError?) -> Void ) -> Self {
        var jsonOption: NSJSONReadingOptions = .AllowFragments
        if let subRequest = self as? ETRequestProtocol {
            jsonOption = subRequest.requestResponseJsonReadingOpion()
        }
        if let data = self.cacheData {
            let responseSerializer = Request.JSONResponseSerializer(options: jsonOption)
            let result = responseSerializer.serializeResponse(
                self.request?.request,
                self.request?.response,
                data,
                nil
            )
            completion(result.value, result.error)
        } else {
            guard let request = self.request else {
                completion(nil, Error.errorWithCode(-6008, failureReason: "no request"))
                return self
            }
            
            request.responseJSON(options: jsonOption, completionHandler: { response -> Void in
                self.saveResponseToCacheFile()
                completion(response.result.value, response.result.error)
            })

        }
        
        return self
    }
    
    public func responseData(completion: (NSData?, NSError?) -> Void ) -> Self {
        if let data = self.cacheData {
            completion(data, nil)
        } else {
            guard let request = self.request else {
                completion(nil, Error.errorWithCode(-6008, failureReason: "no request"))
                return self
            }
            
            request.responseData({ response -> Void in
                completion(response.result.value, response.result.error)
            })

            
        }
        
        return self
    }
    
}

//MARK: cache
public extension ETRequest {
    private func shouldUseCache() -> Bool {
        if ignoreCache {
            return false
        }
        
        guard let cacheProtocol = self as? ETRequestCacheProtocol else { return false }
        
        let seconds = cacheProtocol.cacheSeconds()
        if seconds < 0 {
            return false
        }

//        guard let cacheFilePath = self.cacheFilePath() else { return false }
        let path = self.cacheFilePath()
        if !NSFileManager.defaultManager().fileExistsAtPath(path) {
            return false
        }
        
        //cache life
        if  seconds < 0 || seconds <  self.cacheFileDuration(path) {
            return false
        }
        
        //cache data
        self.cacheData = NSData(contentsOfFile: path)
        guard let _ = self.cacheData else { return false }
        
        self.dataFromCache = true
        
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
    
    private func saveResponseToCacheFile() -> Void {
        //TODO multi thread
        guard let cacheProtocol = self as? ETRequestCacheProtocol else { return }
        //only cache data
        guard let data = self.request?.delegate.data else { return }
        
        switch cacheProtocol.cacheDataType() {
        default:
            let result = data.writeToFile(self.cacheFilePath(), atomically: true)
            dataCached = true
//            NSKeyedArchiver.archiveRootObject(data, toFile: self.cacheFilePath())
            print("write to file: \(self.cacheFilePath()) result: \(result)")
        }
    }
    private func cacheFilePath() -> String {
        let fullPath = "\(self.cacheBasePath())/\(self.cacheFileName())"
        return fullPath
    }
    
    private func cacheFileName() -> String {
        guard let request = self as? ETRequestProtocol else { fatalError("must implement ETRequestProtocol")}
        let requestUrl = request.requestUrl()
        let baseUrl = request.baseUrl()
        let params = request.requestParams()
        
        let requestInfo = "Method:\(request.requestMethod()) Host:\(baseUrl) Url:\(requestUrl) Param:\(params), AppVersion\(ETRequest.appVersion)"
        let md5 = requestInfo.md5()
        print("filename md5: \(md5)")
        
        return md5
    }
    
    
    private func cacheBasePath() -> String {
        let libraryPaths = NSSearchPathForDirectoriesInDomains(.LibraryDirectory, .UserDomainMask, true)
        let basePath = "\(libraryPaths[0])/RequestCache"
        self.checkDirectory(basePath)
        return basePath
    }
    
    private func cacheFileDuration(path: String) -> Int {
        do {
            let attribute = try NSFileManager.defaultManager().attributesOfItemAtPath(path)
            let modifyDate = attribute[NSFileModificationDate] as! NSDate
            let seconds = Int(-modifyDate.timeIntervalSinceNow ?? -1)
            return seconds
        } catch {
            return -1
        }
    }
    
    private func checkDirectory(path: String) {
        var isDir = ObjCBool(false)
        if !NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isDir) {
            self.createDirectoryAtPath(path)
        } else {
            if !isDir {
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(path)
                    self.createDirectoryAtPath(path)
                } catch {
                    
                }
            }
        }
       
    }
    
    private func createDirectoryAtPath(path: String) {
        do {
            try NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
            //TODO addDoNotBackupAttribute
        } catch {
            print("creat path:\(path) error")
        }
    }
    
    
    public static var appVersion: String {
        let nsObject: AnyObject? = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"]
        let version = nsObject as! String
        return version
    }
}
