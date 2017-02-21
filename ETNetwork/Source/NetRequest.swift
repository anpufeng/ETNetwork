//
//  NetRequest.swift
//  ETNetwork
//
//  Created by ethan on 15/11/4.
//  Copyright © 2015年 ethan. All rights reserved.
//

import Foundation
import CryptoSwift
import Alamofire


public enum ETError: Error {
    case noJobRequest
}

extension ETError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noJobRequest:
            return "no request instance yet"
        }
    }
}


///the request class
open class NetRequest {
    var jobRequest: JobRequest?
        
    weak var manager: NetManager?
    
    open var ignoreCache: Bool = false
    open fileprivate (set)var dataFromCache: Bool = false
    
    /*
    fileprivate var noJobRequestError: NSError {
        return NSError(domain: "etrequest", code: -8000, userInfo: nil)
//        return Alamofire.Error.errorWithCode(-8000, failureReason: "no request, please call start first")
    }
 */
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
        start(NetManager.sharedInstance, ignoreCache: ignoreCache)
    }
    
    open func start(_ manager: NetManager, ignoreCache: Bool) -> Void {
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
        if let uploadProtocol = self as? ETRequestUploadProtocol {
            //only suspend in formdata, will resume in manager when formData encoded success
            if uploadProtocol.formData != nil {
                operationQueue.addOperation({ () -> Void in
                    closure()
                })
            } else {
                closure()
            }
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
public extension NetRequest {
    public var responseAllHeaders: [AnyHashable: Any]? {
        return jobRequest?.response?.allHeaderFields
    }

    public func formDataEncodingError(_ completion: @escaping ((Error) -> Void)) -> Self {
        formDataEncodingErrorCompletion = completion
        
        return self
    }
    
    public func progress(_ closure: ((Int64, Int64) -> Void)? = nil) -> Self {
        reqResponse { () -> () in
            guard let jobRequest = self.jobRequest else {
                return
            }
            
            if let uploadReq = jobRequest as? UploadRequest {
                uploadReq.uploadProgress(closure: { [weak self] (progress) in
                    guard let strongSelf = self else { return }
                    if progress.completedUnitCount == progress.totalUnitCount {
                        strongSelf.manager?.removeFromManager(strongSelf)
                    }
                    if let closure = closure {
                        closure(progress.completedUnitCount, progress.totalUnitCount)
                    }
                })
            } else if let dataReq = jobRequest as? DataRequest {
                dataReq.downloadProgress(closure: { [weak self] (progress) in
                    guard let strongSelf = self else { return }
                    if progress.completedUnitCount == progress.totalUnitCount {
                        strongSelf.manager?.removeFromManager(strongSelf)
                    }
                    if let closure = closure {
                        closure(progress.completedUnitCount, progress.totalUnitCount)
                    }
                })
                
            } else if let downloadReq = jobRequest as? DownloadRequest {
                downloadReq.downloadProgress(closure: { [weak self] (progress) in
                    guard let strongSelf = self else { return }
                    if progress.completedUnitCount == progress.totalUnitCount {
                        strongSelf.manager?.removeFromManager(strongSelf)
                    }
                    if let closure = closure {
                        closure(progress.completedUnitCount, progress.totalUnitCount)
                    }
                })
            }
        }

        return self
    }

    public func responseStr(_ completion: @escaping (String?, Error?) -> Void ) -> Self {
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
                guard let jobRequest = self.jobRequest else {
                    DispatchQueue.main.async(execute: { () -> Void in
                        completion(nil, ETError.noJobRequest)
                    })
                    return
                }
                
                func completionWrapper(string: String?, data: Data?, error: Error?) {
                    if error == nil {
                        if let data = data {
                           self.saveResponseToCacheFile(data)
                        }
                    }
                    self.manager?.removeFromManager(self)
                    completion(string, error)
                }
                
                
                //FIXME:  retain cycle??
                if let dataReq = jobRequest as? DataRequest {
                    dataReq.responseString(completionHandler: { (dataResponse) in
                       completionWrapper(string: dataResponse.value, data: dataResponse.data, error: dataResponse.error)
                    })
                    
                } else if let downloadReq = jobRequest as? DownloadRequest {
                    downloadReq.responseString(completionHandler: { (downloadResponse) in
                        if let url = downloadResponse.destinationURL {
                            do {
                                let data = try Data(contentsOf: url)
                                completionWrapper(string: downloadResponse.value, data: data, error: downloadResponse.error)
                            } catch {
                                completionWrapper(string: downloadResponse.value, data: nil, error: downloadResponse.error)
                            }
                        } else {
                            completionWrapper(string: downloadResponse.value, data: nil, error: downloadResponse.error)
                        }
                    })
                }
            }
        }

       
        return self
    }
    

    public func responseJSON(_ completion: @escaping (Any?, Error?) -> Void ) -> Self {
        reqResponse { () -> () in
            var jsonOption: JSONSerialization.ReadingOptions = .allowFragments
            if let requestProtocol = self as? RequestProtocol {
                jsonOption = requestProtocol.responseJSONReadingOption
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
                    completion(result.value, result.error)
                })
                
            } else {
                guard let jobRequest = self.jobRequest else {
                    DispatchQueue.main.async(execute: { () -> Void in
                        completion(nil, ETError.noJobRequest)
                    })

                    return
                }
                
                func completionWrapper(json: Any?, data: Data?, error: Error?) {
                    if error == nil {
                        if let data = data {
                            self.saveResponseToCacheFile(data)
                        }
                    }
                    self.manager?.removeFromManager(self)
                    completion(json, error)
                }
                
                
                
                if let dataReq = jobRequest as? DataRequest {
                    dataReq.responseJSON(completionHandler: { (dataResponse) in
                        completionWrapper(json: dataResponse.value, data: dataResponse.data, error: dataResponse.error)
                    })
                } else if let downloadReq = jobRequest as? DownloadRequest {
                    downloadReq.responseJSON(completionHandler: { (downloadResponse) in
                        if let url = downloadResponse.destinationURL {
                            do {
                                let data = try Data(contentsOf: url)
                                completionWrapper(json: downloadResponse.value, data: data, error: downloadResponse.error)
                            } catch {
                                completionWrapper(json: downloadResponse.value, data: nil, error: downloadResponse.error)
                            }
                        } else {
                            completionWrapper(json: downloadResponse.value, data: nil, error: downloadResponse.error)
                        }
                        
                    })
                }
            }
        }

        return self
    }
    
    public func responseData(_ completion: @escaping (Data?, Error?) -> Void ) -> Self {
        reqResponse { () -> () in
            if let data = self.loadedCacheData, self.jobRequest == nil {
                DispatchQueue.main.async(execute: { () -> Void in
                    completion(data, nil)
                })

            } else {
                guard let jobRequest = self.jobRequest else {
                    DispatchQueue.main.async(execute: { () -> Void in
                        completion(nil, ETError.noJobRequest)
                    })

                    return
                }
                
                func completionWrapper(data: Data?, error: Error?) {
                    if error == nil {
                        if let data = data {
                            self.saveResponseToCacheFile(data)
                        }
                    }
                    self.manager?.removeFromManager(self)
                    completion(data, error)
                }
                
                if let dataReq = jobRequest as? DataRequest {
                    dataReq.response(responseSerializer: DataRequest.dataResponseSerializer(), completionHandler: { (dataResponse) in
                        completionWrapper(data: dataResponse.data, error: dataResponse.error)
                    })
                } else if let downloadReq = jobRequest as? DownloadRequest {
                    downloadReq.response(responseSerializer: DownloadRequest.dataResponseSerializer(), completionHandler: { (downloadResponse) in
                        completionWrapper(data: downloadResponse.value, error: downloadResponse.error)
                    })
                }
            }
        }

       
        return self
    }
    
    public func httpResponse(_ completion: @escaping (HTTPURLResponse?, Error?) -> Void) -> Self {
        reqResponse { () -> () in
            if let _ = self.loadedCacheData, self.jobRequest == nil {
                DispatchQueue.main.async(execute: { () -> Void in
                    completion(nil, nil)
                })
            } else {
                guard let jobRequest = self.jobRequest else {
                    DispatchQueue.main.async(execute: { () -> Void in
                        completion(nil, ETError.noJobRequest)
                    })
                    return
                }
                
                
                if let dataReq = jobRequest as? DataRequest {
                    dataReq.response(responseSerializer: DataRequest.dataResponseSerializer(), completionHandler: { (dataResponse) in
                        completion(dataResponse.response, dataResponse.error)
                    })
                } else if let downloadReq = jobRequest as? DownloadRequest {
                    downloadReq.response(responseSerializer: DownloadRequest.dataResponseSerializer(), completionHandler: { (downloadResponse) in
                        completion(downloadResponse.response, downloadResponse.error)
                    })
                }
            }
        }

        
        return self
    }
}

//MARK: cache
public extension NetRequest {
    /// the cached string (maybe out of date)
    public var cachedString: String? {
        guard let data = cachedData else { return nil }
        
        var encoding = String.Encoding.utf8
        if let requestProtocol = self as? RequestProtocol {
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
        if let requestProtocol = self as? RequestProtocol {
            jsonOption = requestProtocol.responseJSONReadingOption
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
        
        guard let cacheProtocol = self as? RequestCacheProtocol else { return nil }
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
        
        guard let cacheProtocol = self as? RequestCacheProtocol else { return false }
        
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
        
        guard let cacheProtocol = self as? RequestCacheProtocol else { return false }
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
            guard let cacheProtocol = self as? RequestCacheProtocol else {
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
        guard let requestProtocol = self as? RequestProtocol else { fatalError("must implement RequestProtocol")}
        let requestURL = requestProtocol.requestURL
        let baseURL = requestProtocol.baseURL
        let parameters = requestProtocol.parameters
        let headers = requestProtocol.headers
        
        let requestInfo = "Method:\(requestProtocol.method) Host:\(baseURL) URL:\(requestURL) Headers: \(headers) Parameters:\(parameters), AppVersion\(NetRequest.appVersion)"
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

extension NetRequest: CustomDebugStringConvertible {
    public var debugDescription: String {
        var str = "      \(type(of: self))\n"
        guard let requestProtocol = self as? RequestProtocol else { fatalError("must implement RequestProtocol") }
        if  let authProtocol = self as? ETRequestAuthProtocol {
            str.append("      authenticate: \(authProtocol.credential)\n")
        }
        str.append("      url: \(requestProtocol.baseURL + requestProtocol.requestURL)\n")
        str.append("      method: \(requestProtocol.method.method.rawValue)\n")
        str.append("      paramters: \(requestProtocol.parameters)\n")
        str.append("      headers: \(requestProtocol.headers)\n")
        str.append("      parameterEncoding: \(requestProtocol.parameterEncoding)\n")
        str.append("      responseStringEncoding: \(requestProtocol.responseStringEncoding)\n")
        str.append("      responseJSONReadingOption: \(requestProtocol.responseJSONReadingOption)\n")
        str.append("      responseSerializer: \(requestProtocol.responseSerializer)\n")
        if let cacheProtocol = self as? RequestCacheProtocol {
            if (ignoreCache) {
                str.append("      without using cache\n")
            } else {
                str.append("      cache seconds: \(cacheProtocol.cacheSeconds), cache version: \(cacheProtocol.cacheVersion)\n")
            }
            
        } else {
            str.append("      without using cache\n")
        }
        return str
    }
}

