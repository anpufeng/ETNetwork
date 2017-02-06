//
//  ETRequest.swift
//  ETNetwork
//
//  Created by ethan on 15/11/4.
//  Copyright © 2015年 ethan. All rights reserved.
//

import Foundation
import CryptoSwift
import Alamofire

///the request class
open class ETRequest {
    var jobRequest: JobRequest?
        
    weak var manager: ETManager?
    
    open var ignoreCache: Bool = false
    open fileprivate (set)var dataFromCache: Bool = false
    fileprivate var noJobRequestError: NSError {
        return NSError(domain: "etrequest", code: -8000, userInfo: nil)
//        return Alamofire.Error.errorWithCode(-8000, failureReason: "no request, please call start first")
    }
    var dataCached: Bool = false
    var loadedCacheData: Data?
    lazy var serialQueue: DispatchQueue = {
        return DispatchQueue(label: "etrequest_save_cache", attributes: [])
    }()
    
    var needInOperationQueue = false
    lazy var operationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.isSuspended = true
        return operationQueue
    }()

    var formDataEncodingErrorCompletion: ((Error) -> Void)?
    
    deinit {
        log("\(type(of: self) ) deinit")
        jobRequest?.cancel()
    }
    
    open func start(ignoreCache: Bool = false) {
        start(ETManager.sharedInstance, ignoreCache: ignoreCache)
    }
    
    open func start(_ manager: ETManager, ignoreCache: Bool) -> Void {
        self.ignoreCache = ignoreCache
        if shouldUseCache() {
            if needInOperationQueue {
                self.operationQueue.isSuspended = false
            }
            return
        }

        manager.addRequest(self)
    }
    
    open func cancel() -> Void {
        manager?.cancelRequest(self)
    }
    
    open func suspend() {
        jobRequest?.task?.suspend()
    }
    
    open func resume() {
        jobRequest?.task?.resume()
    }
    
    public init() {

    }

    func reqResponse(_ closure:@escaping () -> ()) {
        if let _ = self as? ETRequestUploadProtocol {
            operationQueue.addOperation({ () -> Void in
                closure()
            })
        } else {
            if needInOperationQueue {
                operationQueue.addOperation({ () -> Void in
                    closure()
                })
            } else {
                closure()
            }

        }
    }
}

//MARK: response
public extension ETRequest {
///TODO change 6008 error
    public var responseAllHeaders: [AnyHashable: Any]? {
        return jobRequest?.response?.allHeaderFields
    }

    public func formDataencodingError(_ completion: @escaping ((Error) -> Void)) -> Self {
        formDataEncodingErrorCompletion = completion
        
        return self
    }
    
    public func progress(_ closure: ((Int64, Int64, Int64) -> Void)? = nil) -> Self {
        reqResponse { () -> () in
            guard let downloadRequest = self.jobRequest as? DownloadRequest else {
                return
            }
            //TODO: fix progress
            downloadRequest.downloadProgress(closure: { (progress) in
                if let closure = closure {
                    closure(progress.completedUnitCount, progress.completedUnitCount, progress.totalUnitCount)
                }
            })
            /*
            downloadRequest.progress({ (readOrWriteBytes, totalBytesReadOrWrite, totalBytesExpectedToReadOrWrite) -> Void in
                if let closure = closure {
                    closure(readOrWriteBytes, totalBytesReadOrWrite, totalBytesExpectedToReadOrWrite)
                }

            })
             */
        }

        return self
    }

    public func response(_ completion: @escaping (Data?, NSError?) -> Void ) -> Self {
        reqResponse { () -> () in
            if let data = self.loadedCacheData, self.jobRequest == nil {
                DispatchQueue.main.async(execute: { () -> Void in
                    completion(data, nil)
                })

            } else {
                guard let jobRequest = self.jobRequest as? DataRequest else {
                    DispatchQueue.main.async(execute: { () -> Void in
                        completion(nil, self.noJobRequestError)
                    })

                    return
                }

                jobRequest.response(completionHandler: { response -> Void in
                    response.response
                    if response.error == nil {
                        self.saveResponseToCacheFile(response.data)
                    }
                     self.manager?.removeFromManager(self)
                    
                    //TODO error ?? NSError
                    completion(response.data, response.error as! NSError)
                })
            }

        }

        return self
    }
    public func responseStr(_ completion: @escaping (String?, NSError?) -> Void ) -> Self {
        reqResponse { () -> () in
            if let data = self.loadedCacheData, self.jobRequest == nil {
                let responseSerializer = DataRequest.stringResponseSerializer(encoding: String.Encoding.utf8)
                let result = responseSerializer.serializeResponse(
                    self.jobRequest?.request,
                    self.jobRequest?.response,
                    data,
                    nil
                )
                DispatchQueue.main.async(execute: { () -> Void in
                    completion(result.value, result.error as NSError?)
                })

            } else {
                guard let jobRequest = self.jobRequest as? DataRequest else {
                    DispatchQueue.main.async(execute: { () -> Void in
                        completion(nil, self.noJobRequestError)
                    })
                    return
                }
                jobRequest.responseString(completionHandler: { response -> Void in
                    if response.result.error == nil {
                        self.saveResponseToCacheFile(response.data)
                    }
                     self.manager?.removeFromManager(self)
                    
                    completion(response.result.value, response.result.error as NSError?)
                })
            }
        }

       
        return self
    }
    

    public func responseJson(_ completion: @escaping (AnyObject?, NSError?) -> Void ) -> Self {
        reqResponse { () -> () in
            var jsonOption: JSONSerialization.ReadingOptions = .allowFragments
            if let requestProtocol = self as? ETRequestProtocol {
                jsonOption = requestProtocol.responseJsonReadingOption
            }
            if let data = self.loadedCacheData, self.jobRequest == nil {
                let responseSerializer = DataRequest.jsonResponseSerializer(options: jsonOption)
                let result = responseSerializer.serializeResponse(
                    self.jobRequest?.request,
                    self.jobRequest?.response,
                    data,
                    nil
                )
                DispatchQueue.main.async(execute: { () -> Void in
                    //TODO: AS ANYOBJ &&  AS NSERROR
                    completion(result.value as AnyObject?, result.error as NSError?)
                })
                
            } else {
                guard let jobRequest = self.jobRequest as? DataRequest else {
                    DispatchQueue.main.async(execute: { () -> Void in
                        completion(nil, self.noJobRequestError)
                    })

                    return
                }
                jobRequest
                jobRequest.responseJSON(options: jsonOption, completionHandler: { response -> Void in
                    if response.result.error == nil {
                        self.saveResponseToCacheFile(response.data)
                    }
                    self.manager?.removeFromManager(self)
                    //TODO: AS ANYOBJ &&  AS NSERROR
                    completion(response.result.value as AnyObject?, response.result.error as NSError?)
                })
            }
        }

        return self
    }
    
    public func responseData(_ completion: @escaping (Data?, NSError?) -> Void ) -> Self {
        reqResponse { () -> () in
            if let data = self.loadedCacheData, self.jobRequest == nil {
                DispatchQueue.main.async(execute: { () -> Void in
                    completion(data, nil)
                })

            } else {
                guard let jobRequest = self.jobRequest as? DataRequest else {
                    DispatchQueue.main.async(execute: { () -> Void in
                        completion(nil, self.noJobRequestError)
                    })

                    return
                }

                jobRequest.responseData(completionHandler:{ response -> Void in
                    if response.result.error != nil {
                        self.saveResponseToCacheFile(response.data)
                        self.manager?.cancelRequest(self)
                    }
                    //TODO: &&  AS NSERROR
                    completion(response.result.value, response.result.error as NSError?)
                })

            }
        }

       
        return self
    }
    
    public func httpResponse(_ completion: @escaping (HTTPURLResponse?, NSError?) -> Void) -> Self {
        reqResponse { () -> () in
            if let _ = self.loadedCacheData, self.jobRequest == nil {
                DispatchQueue.main.async(execute: { () -> Void in
                    completion(nil, nil)
                })
            } else {
                guard let jobRequest = self.jobRequest as? DataRequest else {
                    DispatchQueue.main.async(execute: { () -> Void in
                        completion(nil, self.noJobRequestError)
                    })
                    return
                }
                jobRequest.response(completionHandler: { response -> Void in
                    //TODO: &&  AS NSERROR
                    completion(response.response, response.error as NSError?)
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
        
        var encoding = String.Encoding.utf8
        if let requestProtocol = self as? ETRequestProtocol {
            encoding = requestProtocol.responseStringEncoding
        }

        let responseSerializer = DataRequest.stringResponseSerializer(encoding: encoding)
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
        
        var jsonOption: JSONSerialization.ReadingOptions = .allowFragments
        if let requestProtocol = self as? ETRequestProtocol {
            jsonOption = requestProtocol.responseJsonReadingOption
        }
     
        
        let responseSerializer = DataRequest.jsonResponseSerializer(options: jsonOption)
        let result = responseSerializer.serializeResponse(
            jobRequest?.request,
            jobRequest?.response,
            data,
            nil
        )

        return result.value as AnyObject?
    }
    
    /// the cached data (maybe out of date)
    public var cachedData: Data? {
        if (loadedCacheData != nil && dataFromCache) {
            return self.loadedCacheData
        }
        let path = cacheFilePath()
        if !FileManager.default.fileExists(atPath: path) {
            return nil
        }
        
        guard let cacheProtocol = self as? ETRequestCacheProtocol else { return nil }
        if cacheProtocol.cacheVersion != cacheVersionFileContent() {
            //FIXME: remove cache file?
            return nil
        }
        let data = try? Data(contentsOf: URL(fileURLWithPath: path))
        return data
    }

    fileprivate func shouldUseCache() -> Bool {
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
        if !FileManager.default.fileExists(atPath: path) {
            return false
        }
        
        //cache life
        let passed = cacheFileDuration(path)
        if  passed < 0 || seconds < passed {
            return false
        }
        
        //cache data
        loadedCacheData = try? Data(contentsOf: URL(fileURLWithPath: path))
        guard let _ = loadedCacheData else { return false }
        
        dataFromCache = true
        
        return true
    }
    
    fileprivate func shouldStoreCache() -> Bool {
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
    
    func saveResponseToCacheFile(_ data: Data?) -> Void {
        if shouldStoreCache() {
            //only cache data
            guard let data = data else {
                return
            }
            guard let cacheProtocol = self as? ETRequestCacheProtocol else {
                return
            }
            
            serialQueue.async { () -> Void in
                let result = (try? data.write(to: URL(fileURLWithPath: self.cacheFilePath()), options: [.atomic])) != nil
                NSKeyedArchiver.archiveRootObject(NSNumber(value: cacheProtocol.cacheVersion as UInt64), toFile: self.cacheVersionFilePath())
                self.dataCached = true
                log("write to file: \(self.cacheFilePath()) result: \(result)")
            }
        }
    }
    fileprivate func cacheFilePath() -> String {
        let fullPath = "\(cacheBasePath())/\(cacheFileName())"
        return fullPath
    }
    
    fileprivate func cacheVersionFilePath() -> String {
        let cacheVersionFileName = "\(cacheFileName()).version"
        let fullPath = "\(cacheBasePath())/\(cacheVersionFileName)"
        return fullPath
        
    }
    
    fileprivate func cacheVersionFileContent() -> UInt64 {
        let path = cacheVersionFilePath()
        if FileManager.default.fileExists(atPath: path) {
            guard let number = NSKeyedUnarchiver.unarchiveObject(withFile: path) else { return 0}
            return (number as AnyObject).uint64Value
        }
        
        return 0
    }
    
    fileprivate func cacheFileName() -> String {
        guard let requestProtocol = self as? ETRequestProtocol else { fatalError("must implement ETRequestProtocol")}
        let requestUrl = requestProtocol.requestUrl
        let baseUrl = requestProtocol.baseUrl
        let parameters = requestProtocol.parameters
        
        let requestInfo = "Method:\(requestProtocol.method) Host:\(baseUrl) Url:\(requestUrl) Parameters:\(parameters), AppVersion\(ETRequest.appVersion)"
        let md5 = requestInfo.md5()
//        log("filename md5: \(md5)")
        
        return md5
    }
    
    public func identifier() -> String {
        return cacheFileName()
    }
    
    
    fileprivate func cacheBasePath() -> String {
        let libraryPaths = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
        let basePath = "\(libraryPaths[0])/RequestCache"
        checkDirectory(basePath)
        return basePath
    }
    
    fileprivate func cacheFileDuration(_ path: String) -> Int {
        do {
            let attribute = try FileManager.default.attributesOfItem(atPath: path)
            let modifyDate = attribute[FileAttributeKey.modificationDate] as! Date
            let seconds = Int(-modifyDate.timeIntervalSinceNow ?? -1)
            return seconds
        } catch {
            return -1
        }
    }
    
    fileprivate func checkDirectory(_ path: String) {
        var isDir = ObjCBool(false)
        if !FileManager.default.fileExists(atPath: path, isDirectory: &isDir) {
            createDirectoryAtPath(path)
        } else {
            if !isDir.boolValue {
                do {
                    try FileManager.default.removeItem(atPath: path)
                    createDirectoryAtPath(path)
                } catch {
                    
                }
            }
        }
       
    }
    
    fileprivate func createDirectoryAtPath(_ path: String) {
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            //TODO addDoNotBackupAttribute
        } catch {
            log("creat path:\(path) error")
        }
    }
    
    
    public static var appVersion: String {
        let nsObject: AnyObject? = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as AnyObject?
        let version = nsObject as! String
        return version
    }
    
    public static func suggestedDownloadDestination() -> (URL, HTTPURLResponse) -> (destinationURL: URL, options: Alamofire.DownloadRequest.DownloadOptions) {
        return DownloadRequest.suggestedDownloadDestination()
    }
}

extension ETRequest: CustomDebugStringConvertible {
    public var debugDescription: String {
        var str = "      \(type(of: self))\n"
        guard let requestProtocol = self as? ETRequestProtocol else { fatalError("must implement ETRequestProtocol") }
        if  let authProtocol = self as? ETRequestAuthProtocol {
            str.append("      authenticate: \(authProtocol.credential)\n")
        }
        str.append("      url: \(requestProtocol.baseUrl + requestProtocol.requestUrl)\n")
        str.append("      method: \(requestProtocol.method.method.rawValue)\n")
        str.append("      paramters: \(requestProtocol.parameters)\n")
        str.append("      headers: \(requestProtocol.headers)\n")
        str.append("      parameterEncoding: \(requestProtocol.parameterEncoding)\n")
        str.append("      responseStringEncoding: \(requestProtocol.responseStringEncoding)\n")
        str.append("      responseJsonReadingOption: \(requestProtocol.responseJsonReadingOption)\n")
        str.append("      responseSerializer: \(requestProtocol.responseSerializer)\n")
        if let cacheProtocol = self as? ETRequestCacheProtocol {
            str.append("      cache seconds: \(cacheProtocol.cacheSeconds), cache version: \(cacheProtocol.cacheVersion)\n")
        } else {
            str.append("      without using cache\n")
        }
        return str
    }
}

