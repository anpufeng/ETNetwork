//
//  ETRequest.swift
//  ETNetwork
//
//  Created by ethan on 15/11/4.
//  Copyright © 2015年 ethan. All rights reserved.
//

import Foundation
import CryptoSwift

///the requst class
public class ETRequest {
    public weak var delegate: ETRequestDelegate?
    
    var jobRequest: JobRequest?
    weak var manager: ETManager?
    
    public var ignoreCache: Bool = false
    var dataFromCache: Bool = false
    var dataCached: Bool = false
    var loadedCacheData: NSData?
    lazy var serialQueue: dispatch_queue_t = {
        return dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL)
    }()

    lazy var operationQueue: NSOperationQueue = {
        let operationQueue = NSOperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.suspended = true
        return operationQueue
    }()

    var formDataEncodingErrorCompletion: ((ErrorType) -> Void)?
    
    deinit {
        ETLog("\(self.dynamicType ) deinit")
        operationQueue.cancelAllOperations()
        operationQueue.suspended = false
        jobRequest?.cancel()
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
    
    public func cancel() -> Void {
        manager?.cancelRequest(self)
    }
    
    public func suspend() {
        jobRequest?.task.suspend()
    }
    
    public func resume() {
        jobRequest?.task.resume()
    }
    public var requestIdentifier: Int? {
        //no request exist if use cache
        guard let jobRequest = jobRequest else {  return nil }
        return jobRequest.task.taskIdentifier
    }
    
    public init() {

    }
}

//MARK: response
public extension ETRequest {
///TODO change 6008 error
    public var responseAllHeaders: [NSObject : AnyObject]? {
        return jobRequest?.response?.allHeaderFields
    }

    public func formDataencodingError(completion: ((ErrorType) -> Void)) -> Self {
        self.formDataEncodingErrorCompletion = completion
        
        return self
    }
    
    public func progress(closure: ((Int64, Int64, Int64) -> Void)? = nil) -> Self {
        operationQueue.addOperationWithBlock { () -> Void in
            self.jobRequest?.progress({ (readOrWriteBytes, totalBytesReadOrWrite, totalBytesExpectedToReadOrWrite) -> Void in
                if let closure = closure {
                    closure(readOrWriteBytes, totalBytesReadOrWrite, totalBytesExpectedToReadOrWrite)
                }
                
            })
        }
        
        
        return self
    }

    public func responseStr(completion: (String?, NSError?) -> Void ) -> Self {
        if let data = self.loadedCacheData  where self.jobRequest == nil {
            let responseSerializer = Request.stringResponseSerializer(encoding: NSUTF8StringEncoding)
            let result = responseSerializer.serializeResponse(
                self.jobRequest?.request,
                self.jobRequest?.response,
                data,
                nil
            )
            completion(result.value, result.error)
        } else {
            operationQueue.addOperationWithBlock { () -> Void in
                guard let jobRequest = self.jobRequest else {
                    completion(nil, Error.errorWithCode(-6008, failureReason: "no request"))
                    return
                }
                
                jobRequest.responseString(completionHandler: { response -> Void in
                    completion(response.result.value, response.result.error)
                })
            }
            
        }
       

        return self
    }
    
    public func responseJson(completion: (AnyObject?, NSError?) -> Void ) -> Self {
        var jsonOption: NSJSONReadingOptions = .AllowFragments
        if let requestProtocol = self as? ETRequestProtocol {
            jsonOption = requestProtocol.responseJsonReadingOption
        }
        if let data = self.loadedCacheData where self.jobRequest == nil {
            let responseSerializer = Request.JSONResponseSerializer(options: jsonOption)
            let result = responseSerializer.serializeResponse(
                self.jobRequest?.request,
                self.jobRequest?.response,
                data,
                nil
            )
            completion(result.value, result.error)
        } else {
            operationQueue.addOperationWithBlock { () -> Void in
                guard let jobRequest = self.jobRequest else {
                    completion(nil, Error.errorWithCode(-6008, failureReason: "no request"))
                    return
                }
                
                jobRequest.responseJSON(options: jsonOption, completionHandler: { response -> Void in
                    completion(response.result.value, response.result.error)
                })
            }
        }

        return self
    }
    
    public func responseData(completion: (NSData?, NSError?) -> Void ) -> Self {
        if let data = self.loadedCacheData  where self.jobRequest == nil {
            completion(data, nil)
        } else {
            operationQueue.addOperationWithBlock { () -> Void in
                guard let jobRequest = self.jobRequest else {
                    completion(nil, Error.errorWithCode(-6008, failureReason: "no request"))
                    return
                }
                
                jobRequest.responseData({ response -> Void in
                    completion(response.result.value, response.result.error)
                })
            }
        }
       

        return self
    }
    
    public func httpResponse(completion: (NSHTTPURLResponse?, NSError?) -> Void) -> Self {
        if let _ = self.loadedCacheData  where self.jobRequest == nil {
            completion(nil, nil)
        } else {
            operationQueue.addOperationWithBlock { () -> Void in
                guard let jobRequest = self.jobRequest else {
                    completion(nil, Error.errorWithCode(-6008, failureReason: "no request"))
                    return
                }
                
                jobRequest.response(completionHandler: { response -> Void in
                    completion(response.1, response.3)
                })
            }
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
        if let requestProtocol = self as? ETRequestProtocol {
            encoding = requestProtocol.responseStringEncoding
        }

        
        let responseSerializer = Request.stringResponseSerializer(encoding: encoding)
        let result = responseSerializer.serializeResponse(
            jobRequest?.request,
            jobRequest?.response,
            data,
            nil
        )


        return result.value
    }
    
    /// the cached json (maybe out of date)
    public var cachedJson: AnyObject? {
        guard let data = cachedData else { return nil }
        
        var jsonOption: NSJSONReadingOptions = .AllowFragments
        if let requestProtocol = self as? ETRequestProtocol {
            jsonOption = requestProtocol.responseJsonReadingOption
        }
     
        
        let responseSerializer = Request.JSONResponseSerializer(options: jsonOption)
        let result = responseSerializer.serializeResponse(
            jobRequest?.request,
            jobRequest?.response,
            data,
            nil
        )

        return result.value
    }
    
    /// the cached data (maybe out of date)
    public var cachedData: NSData? {
        if (loadedCacheData != nil && dataFromCache) {
            return self.loadedCacheData
        }
        let path = cacheFilePath()
        if !NSFileManager.defaultManager().fileExistsAtPath(path) {
            return nil
        }
        
        guard let cacheProtocol = self as? ETRequestCacheProtocol else { return nil }
        if cacheProtocol.cacheVersion != cacheVersionFileContent() {
            //FIXME: remove cache file?
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

        // check cache version
        if cacheProtocol.cacheVersion != cacheVersionFileContent() {
            return false
        }
        
        
//        guard let cacheFilePath = cacheFilePath() else { return false }
        //check cache file
        let path = cacheFilePath()
        if !NSFileManager.defaultManager().fileExistsAtPath(path) {
            return false
        }
        
        //cache life
        let passed = cacheFileDuration(path)
        if  passed < 0 || seconds < passed {
            return false
        }
        
        //cache data
        loadedCacheData = NSData(contentsOfFile: path)
        guard let _ = loadedCacheData else { return false }
        
        dataFromCache = true
        
        return true
    }
    
    private func shouldStoreCache() -> Bool {
        if dataFromCache {
            return false
        }
        
        if dataCached {
            return false
        }
        
        guard let cacheProtocol = self as? ETRequestCacheProtocol else { return false }
        if cacheProtocol.cacheSeconds < 0 {
            return false
        }
        
        
        return true
    }
    
    func saveResponseToCacheFile() -> Void {
        if shouldStoreCache() {
            //only cache data
            guard let data = jobRequest?.delegate.data else { return }
            guard let cacheProtocol = self as? ETRequestCacheProtocol else { return }
            dispatch_async(serialQueue) { () -> Void in
                let result = data.writeToFile(self.cacheFilePath(), atomically: true)
                NSKeyedArchiver.archiveRootObject(NSNumber(unsignedLongLong: cacheProtocol.cacheVersion), toFile: self.cacheVersionFilePath())
                self.dataCached = true
                ETLog("write to file: \(self.cacheFilePath()) result: \(result)")
            }
        }
    }
    private func cacheFilePath() -> String {
        let fullPath = "\(cacheBasePath())/\(cacheFileName())"
        return fullPath
    }
    
    private func cacheVersionFilePath() -> String {
        let cacheVersionFileName = "\(cacheFileName()).version"
        let fullPath = "\(cacheBasePath())/\(cacheVersionFileName)"
        return fullPath
        
    }
    
    private func cacheVersionFileContent() -> UInt64 {
        let path = cacheVersionFilePath()
        if NSFileManager.defaultManager().fileExistsAtPath(path) {
            guard let number = NSKeyedUnarchiver.unarchiveObjectWithFile(path) else { return 0}
            return number.unsignedLongLongValue
        }
        
        return 0
    }
    
    private func cacheFileName() -> String {
        guard let requestProtocol = self as? ETRequestProtocol else { fatalError("must implement ETRequestProtocol")}
        let requestUrl = requestProtocol.requestUrl
        let baseUrl = requestProtocol.baseUrl
        let parameters = requestProtocol.parameters
        
        let requestInfo = "Method:\(requestProtocol.method) Host:\(baseUrl) Url:\(requestUrl) Parameters:\(parameters), AppVersion\(ETRequest.appVersion)"
        let md5 = requestInfo.md5()
        ETLog("filename md5: \(md5)")
        
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
            ETLog("creat path:\(path) error")
        }
    }
    
    
    public static var appVersion: String {
        let nsObject: AnyObject? = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"]
        let version = nsObject as! String
        return version
    }
    
    public static func suggestedDownloadDestination() -> (NSURL, NSHTTPURLResponse) -> NSURL {
        return JobRequest.suggestedDownloadDestination()
    }
}

extension ETRequest: CustomDebugStringConvertible {
    public var debugDescription: String {
        var str = "      \(self.dynamicType)\n"
        guard let requestProtocol = self as? ETRequestProtocol else { fatalError("must implement ETRequestProtocol") }
        if  let authProtocol = self as? ETRequestAuthProtocol {
            str.appendContentsOf("      authenticate: \(authProtocol.credential)\n")
        }
        str.appendContentsOf("      url: \(requestProtocol.requestUrl)\n")
        str.appendContentsOf("      method: \(requestProtocol.method.method.rawValue)\n")
        str.appendContentsOf("      paramters: \(requestProtocol.parameters)\n")
        str.appendContentsOf("      headers: \(requestProtocol.headers)\n")
        str.appendContentsOf("      parameterEncoding: \(requestProtocol.parameterEncoding)\n")
        str.appendContentsOf("      responseStringEncoding: \(requestProtocol.responseStringEncoding)\n")
        str.appendContentsOf("      responseJsonReadingOption: \(requestProtocol.responseJsonReadingOption)\n")
        str.appendContentsOf("      responseSerializer: \(requestProtocol.responseSerializer)\n")
        if let cacheProtocol = self as? ETRequestCacheProtocol {
            str.appendContentsOf("      cache seconds: \(cacheProtocol.cacheSeconds), cache version: \(cacheProtocol.cacheVersion)\n")
        } else {
            str.appendContentsOf("      without using cache\n")
        }
        return str
    }
}

