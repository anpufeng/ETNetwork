//
//  ETManager.swift
//  ETNetwork
//
//  Created by ethan on 15/11/4.
//  Copyright © 2015年 ethan. All rights reserved.
//

import Foundation


public func ETLog<T>(object: T, _ file: String = __FILE__, _ function: String = __FUNCTION__, _ line: Int = __LINE__) {
    if ETManager.logEnable {
        let path = file as NSString
        let fileNameWithoutPath = path.lastPathComponent
        let info = "\(NSDate()): \(fileNameWithoutPath).\(function)[\(line)]: \(object)"
        print(info)
    }
}


public class ETManager {
    public static var logEnable = true
    
    public static let sharedInstance: ETManager = {
        return ETManager()
    }()
    
    public var timeoutIntervalForResource: NSTimeInterval = 25 {
        didSet {
            jobManager.session.configuration.timeoutIntervalForResource = timeoutIntervalForResource
        }
    }
    public var timeoutIntervalForRequest: NSTimeInterval = 15 {
        didSet {
           jobManager.session.configuration.timeoutIntervalForRequest = timeoutIntervalForRequest
        }
    }
    private let jobManager: JobManager
    private var sudRequests: [Int: ETRequest] = [:]
    private let concurrentQueue = dispatch_queue_create(nil, DISPATCH_QUEUE_CONCURRENT)
    
    private struct AssociatedKey {
        static var inneKey = "etrequest"
    }
    
    subscript(request: ETRequest) -> ETRequest? {
        get {
            var req: ETRequest?
            guard let identifier = request.requestIdentifier else { return req }
            dispatch_sync(concurrentQueue) {
                req = self.sudRequests[identifier]
            }
            
            return req
        }
        
        set {
            guard let identifier = request.requestIdentifier else { return }
            dispatch_barrier_async(concurrentQueue) {
                self.sudRequests[identifier] = newValue
            }
        }
    }
    
    public init() {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = Manager.defaultHTTPHeaders
        configuration.timeoutIntervalForResource = timeoutIntervalForResource
        configuration.timeoutIntervalForRequest = timeoutIntervalForRequest
        jobManager = JobManager(configuration: configuration)
        jobManager.delegate.taskDidComplete = { (session, task, error) -> Void in
            //use the default process before our job
            if let delegate = self.jobManager.delegate[task] {
                delegate.URLSession(session, task: task, didCompleteWithError: error)
            }

            //addition job
            let request  = objc_getAssociatedObject(task, &AssociatedKey.inneKey) as? ETRequest
            if let request = request {
                ETLog(request.jobRequest.debugDescription)
                if let _ = error {
                    request.delegate?.requestFailed(request)
                } else {
                    request.delegate?.requestFinished(request)
                    request.saveResponseToCacheFile()
                }
                
                self.cancelRequest(request)
            } else {
                ETLog("objc_getAssociatedObject fail ")
            }
        }

    }

    func addRequest(request: ETRequest) {
        if let requestProtocol = request as? ETRequestProtocol {
            let method = requestProtocol.method.method
            let headers = requestProtocol.headers
            let serializer = requestProtocol.responseSerializer
            let parameters = requestProtocol.parameters
            let encoding = requestProtocol.parameterEncoding.encode
            
            var req: Request?
            switch requestProtocol.taskType {
            case .Data:
                req = jobManager.request(method, buildRequestUrl(request), parameters: parameters, encoding: encoding, headers: headers)
            case .Download:
                guard let _ = request as? ETRequestDownloadProtocol else { fatalError("not implement ETRequestDownloadProtocol") }
                let destination = Request.suggestedDownloadDestination(directory: .DocumentDirectory, domain: .UserDomainMask)
                req = jobManager.download(method, buildRequestUrl(request), parameters: parameters, encoding: encoding, headers: headers, destination: destination)

                
            case .Upload:
                guard let _ = request as? ETREquestUploadProtocol else { fatalError("not implement ETREquestUploadProtocol") }
                req = jobManager.upload(method, buildRequestUrl(request), headers: headers, file: NSURL(fileURLWithPath: ""))
                
            }
                    
            objc_setAssociatedObject(req!.task, &AssociatedKey.inneKey, request, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
            request.jobRequest = req
            

            /*
            switch serializer {
            case .Data:
                req.responseData({ response in
                    self.handleRequestResult(request, response: response)
                })
                
            case .String:
                req.responseString(encoding: NSUTF8StringEncoding, completionHandler: { response in
                    self.handleRequestResult(request, response: response)
                })
            case .Json:
                req.responseJSON(options: .AllowFragments, completionHandler: { response in
                    self.handleRequestResult(request, response: response)
                })
            case .PropertyList:
                req.responseJSON(options: .AllowFragments, completionHandler: { response in
                    self.handleRequestResult(request, response: response)
                })
                
                
            }
            */
            
            //add request dictionary
            self[request] = request
            
        } else {
            fatalError("must implement ETRequestProtocol")
        }

    }
    
    func cancelRequest(request: ETRequest) {
        request.jobRequest?.cancel()
        self[request] = nil
    }
    
    func cancelAllRequests() {
        let dic = sudRequests as NSDictionary
        let copyDic: NSMutableDictionary = dic.mutableCopy() as! NSMutableDictionary
        
        for (_, value) in copyDic {
            let request = value as! ETRequest
            cancelRequest(request)
        }
    }
    
    //MARK: private
    /*
    //responseString
    private func handleRequestResult(request: ETRequest, response: Response<String, NSError> ) {
        let req = response.request
        //guard request == req else { return }
        debugPrint(request.request)
        var succeed = true
        if (response.result.error != nil) {
            succeed = false
        }
        
        
        
        if succeed {
            request.delegate?.requestFinished(request)
        } else {
            request.delegate?.requestFailed(request)
        }
    }
    
    ///responseJSON|AnyObject
    private func handleRequestResult(request: ETRequest, response: Response<AnyObject, NSError> ) {
        var succeed = true
        debugPrint(request.request)
        if (response.result.error != nil) {
            succeed = false
        } else {
            //request.resJson = response.result.value
        }
        
        
        
        if succeed {
            request.delegate?.requestFinished(request)
        } else {
            request.delegate?.requestFailed(request)
        }
    }
    
    ///responseData
    private func handleRequestResult(request: ETRequest, response: Response<NSData, NSError> ) {
        debugPrint(request.request)
    }
    
*/
    private func buildRequestUrl(request: ETRequest) -> String {
        if let requestProtocol = request as? ETRequestProtocol  {
            if requestProtocol.requestUrl.hasPrefix("http") {
                return requestProtocol.requestUrl
            }
            
            /*
            var baseUrl: String
            if let url  = requestProtocol.baseUrl?() {
                baseUrl = url
            } else {
                baseUrl = config.baseUrl
            }
            */
            
            return "\(requestProtocol.baseUrl)\(requestProtocol.requestUrl)"
            
        } else {
            fatalError("must implement ETRequestProtocol")
        }
    }
}
