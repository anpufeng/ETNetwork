//
//  ETRequest.swift
//  ETNetwork
//
//  Created by ethan on 15/11/4.
//  Copyright © 2015年 ethan. All rights reserved.
//

import Foundation
import CryptoSwift

///wrap the alamofire method
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

///wrap the alamofire ParameterEncoding
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


/**
 the request delegate callback
*/
public protocol ETRequestDelegate : class {
    func requestFinished(request: ETRequest)
    func requestFailed(request: ETRequest)
}

/**
 make ETRequestDelegate callback method optional
*/
public  extension ETRequestDelegate {
    func requestFinished(request: ETRequest) {
        
    }
    func requestFailed(request: ETRequest) {
        
    }
}

/**
 conform to custom your own NSURLRequest
*/
public protocol ETRequestCustom {
    var customUrlRequest: NSURLRequest { get}
}

/**
 conform to custom your own request cache
*/
public protocol ETRequestCacheProtocol: class {
    var cacheSeconds: Int { get }
//    func cacheDataType() -> ETResponseSerializer
}

public extension ETRequestCacheProtocol {
    
//    func cacheDataType() -> ETResponseSerializer {
//        return .Data
//    }
}

/**
 your subclass must conform this protocol
*/
 public protocol ETRequestProtocol : class {
    var requestUrl: String { get }
    
    var baseUrl: String { get }
    var method: ETRequestMethod { get }
    var parameters:  [String: AnyObject]? { get }
    var timeout: Int { get }
    var headers: [String: String]? { get }
    var parameterEncoding: ETRequestParameterEncoding { get }
    var responseStringEncoding: NSStringEncoding { get }
    var responseJsonReadingOption: NSJSONReadingOptions { get }
    var responseSerializer: ETResponseSerializer { get }
}

/**
 make ETRequestProtocol some methed default and optional
*/
public extension ETRequestProtocol {
    
    var baseUrl: String { return ETNetworkConfig.sharedInstance.baseUrl }
    
    var method: ETRequestMethod { return .Post }
    var parameters: [String: AnyObject]? { return nil }
    var timeout: Int { return 20 }
    
    var headers: [String: String]? { return nil }
    var parameterEncoding: ETRequestParameterEncoding { return  .Json }
    var responseStringEncoding: NSStringEncoding { return NSUTF8StringEncoding }
    var responseJsonReadingOption: NSJSONReadingOptions { return .AllowFragments }
    var responseSerializer: ETResponseSerializer { return .Json }
}

///the requst class
public class ETRequest {
    public weak var delegate: ETRequestDelegate?
    
    var request: Request?
    
    public var ignoreCache: Bool = false
    var dataFromCache: Bool = false
    var dataCached: Bool = false
    var cacheData: NSData?
    lazy var queue: dispatch_queue_t = {
        return dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL)
    }()
    
    deinit {
        print("ETRequest  deinit")
    }
    
    public func start(ignoreCache: Bool = false) {
        start(ETManager.sharedInstance, ignoreCache: ignoreCache)
    }
    
    public func start(manager: ETManager, ignoreCache: Bool) -> Void {
        self.ignoreCache = ignoreCache
        if shouldUseCache() {
            delegate?.requestFinished(self)
            return
        }
        
        manager.addRequest(self)
    }
    
    public func start(completion: () -> Void) {
        self.start()
        completion()
    }
    
    public func cancel() -> Void {
        request?.cancel()
    }
    
    
    public init() {

    }
}

//MARK: response
public extension ETRequest {
///TODO change 6008 error
    public var responseAllHeaders: [NSObject : AnyObject]? {
        return request?.response?.allHeaderFields
    }
    
    public func responseStr(completion: (String?, NSError?) -> Void ) -> Self {
        if let data = cacheData  where request == nil {
            let responseSerializer = Request.stringResponseSerializer(encoding: NSUTF8StringEncoding)
            let result = responseSerializer.serializeResponse(
                request?.request,
                request?.response,
                data,
                nil
            )
            completion(result.value, result.error)
        } else {
            guard let request = request else {
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
            jsonOption = subRequest.responseJsonReadingOption
        }
        if let data = cacheData where request == nil {
            let responseSerializer = Request.JSONResponseSerializer(options: jsonOption)
            let result = responseSerializer.serializeResponse(
                request?.request,
                request?.response,
                data,
                nil
            )
            completion(result.value, result.error)
        } else {
            guard let request = request else {
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
        if let data = cacheData  where request == nil {
            completion(data, nil)
        } else {
            guard let request = request else {
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
    /// the cached string (maybe out of date)
    public var cachedString: String? {
        guard let data = cachedData else { return nil }
        
        var encoding = NSUTF8StringEncoding
        if let subRequest = self as? ETRequestProtocol {
            encoding = subRequest.responseStringEncoding
        }

        
        let responseSerializer = Request.stringResponseSerializer(encoding: encoding)
        let result = responseSerializer.serializeResponse(
            request?.request,
            request?.response,
            data,
            nil
        )


        return result.value
    }
    
    /// the cached json (maybe out of date)
    public var cachedJson: AnyObject? {
        guard let data = cachedData else { return nil }
        
        var jsonOption: NSJSONReadingOptions = .AllowFragments
        if let subRequest = self as? ETRequestProtocol {
            jsonOption = subRequest.responseJsonReadingOption
        }
     
        
        let responseSerializer = Request.JSONResponseSerializer(options: jsonOption)
        let result = responseSerializer.serializeResponse(
            request?.request,
            request?.response,
            data,
            nil
        )

        return result.value
    }
    
    /// the cached data (maybe out of date)
    public var cachedData: NSData? {
        let path = cacheFilePath()
        if !NSFileManager.defaultManager().fileExistsAtPath(path) {
            return nil
        }
        
        let data = NSData(contentsOfFile: path)
        return data
    }

    private func shouldUseCache() -> Bool {
        if ignoreCache {
            return false
        }
        
        guard let cacheProtocol = self as? ETRequestCacheProtocol else { return false }
        
        let seconds = cacheProtocol.cacheSeconds
        if seconds < 0 {
            return false
        }

//        guard let cacheFilePath = cacheFilePath() else { return false }
        let path = cacheFilePath()
        if !NSFileManager.defaultManager().fileExistsAtPath(path) {
            return false
        }
        
        //cache life
        if  seconds < 0 || seconds <  cacheFileDuration(path) {
            return false
        }
        
        //cache data
        cacheData = NSData(contentsOfFile: path)
        guard let _ = cacheData else { return false }
        
        dataFromCache = true
        
        return true
    }
    
    private func shouldStoreCache() -> Bool {
        if dataFromCache {
            return false
        }
        
        guard let cacheProtocol = self as? ETRequestCacheProtocol else { return false }
        if cacheProtocol.cacheSeconds < 0 {
            return false
        }
        
        
        return true
    }
    
    private func saveResponseToCacheFile() -> Void {
        if shouldStoreCache() {
            //only cache data
            guard let data = request?.delegate.data else { return }
            
            dispatch_async(queue) { () -> Void in
                let result = data.writeToFile(self.cacheFilePath(), atomically: true)
                self.dataCached = true
                print("write to file: \(self.cacheFilePath()) result: \(result)")
            }
        }
    }
    private func cacheFilePath() -> String {
        let fullPath = "\(cacheBasePath())/\(cacheFileName())"
        return fullPath
    }
    
    private func cacheFileName() -> String {
        guard let request = self as? ETRequestProtocol else { fatalError("must implement ETRequestProtocol")}
        let requestUrl = request.requestUrl
        let baseUrl = request.baseUrl
        let parameters = request.parameters
        
        let requestInfo = "Method:\(request.method) Host:\(baseUrl) Url:\(requestUrl) Parameters:\(parameters), AppVersion\(ETRequest.appVersion)"
        let md5 = requestInfo.md5()
        print("filename md5: \(md5)")
        
        return md5
    }
    
    
    private func cacheBasePath() -> String {
        let libraryPaths = NSSearchPathForDirectoriesInDomains(.LibraryDirectory, .UserDomainMask, true)
        let basePath = "\(libraryPaths[0])/RequestCache"
        checkDirectory(basePath)
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
            createDirectoryAtPath(path)
        } else {
            if !isDir {
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(path)
                    createDirectoryAtPath(path)
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
