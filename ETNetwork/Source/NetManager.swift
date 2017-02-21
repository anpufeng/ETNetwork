//
//  NetManager.swift
//  ETNetwork
//
//  Created by ethan on 15/11/4.
//  Copyright © 2015年 ethan. All rights reserved.
//

import Foundation
import Alamofire


public func log<T>(_ object: T, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
    if NetManager.logEnable {
        let path = file as NSString
        let fileNameWithoutPath = path.lastPathComponent
        let info = "\(Date()): \(fileNameWithoutPath).\(function)[\(line)]: \(object)"
        print(info)
    }
}

open class NetManager {
    open static var logEnable = true
    
    open static let sharedInstance: NetManager = {
        return NetManager()
    }()
    
    fileprivate let jobManager: JobManager
    fileprivate var subRequests: [String: NetRequest] = [:]
    fileprivate let concurrentQueue = DispatchQueue(label: "concurrent_etmanager", attributes: DispatchQueue.Attributes.concurrent)
    
    fileprivate struct AssociatedKey {
        static var inneKey = "etrequest"
    }
    
    subscript(request: NetRequest) -> NetRequest? {
        get {
            var req: NetRequest?
            concurrentQueue.sync {
                req = self.subRequests[request.identifier()]
            }
            
            return req
        }
        
        set {
            concurrentQueue.async(flags: .barrier, execute: {
                self.subRequests[request.identifier()] = newValue
            }) 
        }
    }
    public convenience init() {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = JobManager.defaultHTTPHeaders
        configuration.timeoutIntervalForRequest = 15
        self.init(configuration: configuration)
    }

    public convenience init(timeoutForRequest: TimeInterval, timeoutForResource: TimeInterval = 7 * 24 * 3600) {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = JobManager.defaultHTTPHeaders
        configuration.timeoutIntervalForRequest = timeoutForRequest
        configuration.timeoutIntervalForResource = timeoutForResource
        self.init(configuration: configuration)
    }

    public init(configuration: URLSessionConfiguration) {
        jobManager = JobManager(configuration: configuration)
    }

    deinit {
        log("\(type(of: self) ) deinit")
    }

    func addRequest(_ request: NetRequest) {
        if let req = self[request] {
            log("already in processing, nothing to do")
            return
        }
        if let requestProtocol = request as? RequestProtocol {
            let method = requestProtocol.method.method
            let headers = requestProtocol.headers
            let serializer = requestProtocol.responseSerializer
            let parameters = requestProtocol.parameters
            let encoding = requestProtocol.parameterEncoding.encode
            let url = buildRequestURL(request)
            
            var jobReq: Request?
            switch requestProtocol.taskType {
            case .data:
                jobReq = jobManager.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers)
            case .download:
                guard let downloadProtocol = request as? RequestDownloadProtocol else { fatalError("not implement RequestDownloadProtocol") }
                 let destination = downloadProtocol.downloadDestination()
                if let resumeData = downloadProtocol.resumeData {
                    jobReq = jobManager.download(resumingWith: resumeData, to: destination)
                } else {
                    jobReq = jobManager.download(url, method: method, parameters: parameters, encoding: encoding, headers: headers, to: destination)
                }

            case .uploadFileURL:
                guard let uploadProtocol = request as? RequestUploadProtocol else { fatalError("not implement RequestUploadProtocol") }
                guard let fileURL = uploadProtocol.fileURL else { fatalError("must return fileURL") }
                jobReq = jobManager.upload(fileURL, to: url, method: method, headers: headers)
            case .uploadFileData:
                guard let uploadProtocol = request as? RequestUploadProtocol else { fatalError("not implement RequestUploadProtocol") }
                guard let fileData = uploadProtocol.fileData else { fatalError("must return fileData") }
                jobReq = jobManager.upload(fileData, to: url, method: method, headers: headers)
            case .uploadFormData:
                guard let uploadProtocol = request as? RequestUploadProtocol else { fatalError("not implement RequestUploadProtocol") }
                guard let formData = uploadProtocol.formData else { fatalError("must return formdata") }
                jobManager.upload(multipartFormData: { (multipart) in
                    for wrapped in formData {
                        if wrapped is UploadFormData {
                            let wrapData = wrapped as! UploadFormData
                            if let mimeType = wrapData.mimeType, let fileName = wrapData.fileName {
                                multipart.append(wrapData.data, withName: wrapData.name, fileName: fileName, mimeType: mimeType)
                            } else {
                                multipart.append(wrapData.data, withName: wrapData.name)
                            }
                        } else if wrapped is UploadFormFileURL {
                            let wrapFileURL = wrapped as! UploadFormFileURL
                            if let mimeType = wrapFileURL.mimeType, let fileName = wrapFileURL.fileName {
                                multipart.append(wrapFileURL.fileURL, withName: wrapFileURL.name, fileName: fileName, mimeType: mimeType)
                            } else {
                                multipart.append(wrapFileURL.fileURL, withName: wrapFileURL.name)
                            }
                        } else if wrapped is UploadFormStream {
                            let wrapStream = wrapped as! UploadFormStream
                            if let mimeType = wrapStream.mimeType, let fileName = wrapStream.fileName {
                                multipart.append(wrapStream.stream, withLength: wrapStream.length, name: wrapStream.name, fileName: fileName, mimeType: mimeType)
                            } else {
                                fatalError("must have fileName & mimeType")
                            }
                        } else {
                            fatalError("do not use UploadWrap")
                        }
                    }
                }, to: url, encodingCompletion: { (encodingResult) in
                    switch encodingResult {
                    case .success(let upload, _, _):
                        if let authProtocol = request as? RequestAuthProtocol {
                            if let credential = authProtocol.credential {
                                upload.authenticate(usingCredential: credential)
                            }
                        }
                        objc_setAssociatedObject(upload.task, &AssociatedKey.inneKey, request, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
                        request.jobRequest = upload
                        self[request] = request
                        request.manager = self
                        request.operationQueue.isSuspended = false;
                        
                    case .failure(let encodingError):
                        request.formDataEncodingErrorCompletion?(encodingError)
                    }
                })
            }

            guard let req = jobReq else { return }
            
            if let authProtocol = request as? RequestAuthProtocol {
                if let credential = authProtocol.credential {
                    req.authenticate(usingCredential: credential)
                }
            }
            
            objc_setAssociatedObject(req.task, &AssociatedKey.inneKey, request, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
           
            request.jobRequest = req
            if request.needInOperationQueue {
                request.operationQueue.isSuspended = false
            }
            self[request] = request
            request.manager = self
        } else {
            fatalError("must implement RequestProtocol")
        }

    }
    
    func cancelRequest(_ request: NetRequest) {
        request.jobRequest?.cancel()
        self[request] = nil
    }
    
    func removeFromManager(_ request: NetRequest) {
        self[request] = nil
    }
    open func cancelAllRequests() {
        let dic = subRequests as NSDictionary
        let copyDic: NSMutableDictionary = dic.mutableCopy() as! NSMutableDictionary
        
        for (_, value) in copyDic {
            let request = value as! NetRequest
            cancelRequest(request)
        }
    }
    
    //MARK: private
      fileprivate func buildRequestURL(_ request: NetRequest) -> String {
        if let requestProtocol = request as? RequestProtocol  {
            if requestProtocol.requestURL.hasPrefix("http") {
                return requestProtocol.requestURL
            }
            
            return "\(requestProtocol.baseURL)\(requestProtocol.requestURL)"
            
        } else {
            fatalError("must implement RequestProtocol")
        }
    }
}
