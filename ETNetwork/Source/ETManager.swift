//
//  ETManager.swift
//  ETNetwork
//
//  Created by ethan on 15/11/4.
//  Copyright © 2015年 ethan. All rights reserved.
//

import Foundation
import Alamofire


public func log<T>(_ object: T, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
    if ETManager.logEnable {
        let path = file as NSString
        let fileNameWithoutPath = path.lastPathComponent
        let info = "\(Date()): \(fileNameWithoutPath).\(function)[\(line)]: \(object)"
        print(info)
    }
}

open class ETManager {
    open static var logEnable = true
    
    open static let sharedInstance: ETManager = {
        return ETManager()
    }()
    
    fileprivate let jobManager: JobManager
    fileprivate var subRequests: [String: ETRequest] = [:]
    fileprivate let concurrentQueue = DispatchQueue(label: "concurrent_etmanager", attributes: DispatchQueue.Attributes.concurrent)
    
    fileprivate struct AssociatedKey {
        static var inneKey = "etrequest"
    }
    
    subscript(request: ETRequest) -> ETRequest? {
        get {
            var req: ETRequest?
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

    func addRequest(_ request: ETRequest) {
        if let req = self[request] {
            log("already in processing, nothing to do")
            return
        }
        if let requestProtocol = request as? ETRequestProtocol {
            let method = requestProtocol.method.method
            let headers = requestProtocol.headers
            let serializer = requestProtocol.responseSerializer
            let parameters = requestProtocol.parameters
            let encoding = requestProtocol.parameterEncoding.encode
            let url = buildRequestUrl(request)
            
            var jobReq: Request?
            switch requestProtocol.taskType {
            case .data:
                jobReq = jobManager.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers)
//                jobReq = jobManager.request(method, buildRequestUrl(request), parameters: parameters, encoding: encoding, headers: headers)
            case .download:
                guard let downloadProtocol = request as? ETRequestDownloadProtocol else { fatalError("not implement ETRequestDownloadProtocol") }
                 let destination = downloadProtocol.downloadDestination()
                if let resumeData = downloadProtocol.resumeData {
                    jobReq = jobManager.download(resumingWith: resumeData, to: destination)
//                    jobReq = jobManager.download(resumeData, destination: destination)
                } else {
                    jobReq = jobManager.download(url, method: method, parameters: parameters, encoding: encoding, headers: headers, to: destination)
//                    jobReq = jobManager.download(method, buildRequestUrl(request), parameters: parameters, encoding: encoding, headers: headers, destination: destination)
                }

            case .uploadFileURL:
                guard let uploadProtocol = request as? ETRequestUploadProtocol else { fatalError("not implement ETREquestUploadProtocol") }
                guard let fileURL = uploadProtocol.fileURL else { fatalError("must return fileURL") }
                jobReq = jobManager.upload(fileURL, to: url, method: method, headers: headers)
//                jobReq = jobManager.upload(method, buildRequestUrl(request), headers:headers, file: fileURL)
            case .uploadFileData:
                guard let uploadProtocol = request as? ETRequestUploadProtocol else { fatalError("not implement ETREquestUploadProtocol") }
                guard let fileData = uploadProtocol.fileData else { fatalError("must return fileData") }
                jobReq = jobManager.upload(fileData, to: url, method: method, headers: headers)
//                jobReq = jobManager.upload(method, buildRequestUrl(request), headers:headers, data: fileData)
            case .uploadFormData:
                guard let uploadProtocol = request as? ETRequestUploadProtocol else { fatalError("not implement ETREquestUploadProtocol") }
                guard let formData = uploadProtocol.formData else { fatalError("must return formdata") }
                jobManager.upload(multipartFormData: { (multipart) in
                    for wrapped in formData {
                        if wrapped is UploadFormData {
                            let wrapData = wrapped as! UploadFormData
                            if let mimeType = wrapData.mimeType, let fileName = wrapData.fileName {
                                multipart.append(wrapData.data, withName: wrapData.name, fileName: fileName, mimeType: mimeType)
//                                multipart.appendBodyPart(data: wrapData.data, name: wrapData.name, fileName: fileName, mimeType: mimeType)
                            } else {
                                multipart.append(wrapData.data, withName: wrapData.name)
//                                multipart.appendBodyPart(data: wrapData.data, name: wrapData.name)
                            }
                        } else if wrapped is UploadFormFileURL {
                            let wrapFileURL = wrapped as! UploadFormFileURL
                            if let mimeType = wrapFileURL.mimeType, let fileName = wrapFileURL.fileName {
//                                multipart.appendBodyPart(fileURL: wrapFileURL.fileURL, name: wrapFileURL.name, fileName: fileName, mimeType: mimeType)
                                multipart.append(wrapFileURL.fileURL, withName: wrapFileURL.name, fileName: fileName, mimeType: mimeType)
                            } else {
//                                multipart.appendBodyPart(fileURL: wrapFileURL.fileURL, name: wrapFileURL.name)
                                multipart.append(wrapFileURL.fileURL, withName: wrapFileURL.name)
                            }
                        } else if wrapped is UploadFormStream {
                            let wrapStream = wrapped as! UploadFormStream
                            if let mimeType = wrapStream.mimeType, let fileName = wrapStream.fileName {
//                                multipart.appendBodyPart(stream: wrapStream.stream, length: wrapStream.length, name: wrapStream.name, fileName: fileName, mimeType: mimeType)
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
                        if let authProtocol = request as? ETRequestAuthProtocol {
                            //                                upload.delegate.credential = authProtocol.credential
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
                /*
                jobManager.upload(method, buildRequestUrl(request), multipartFormData: { multipart in
                    for wrapped in formData {
                        if wrapped is UploadFormData {
                            let wrapData = wrapped as! UploadFormData
                            if let mimeType = wrapData.mimeType, let fileName = wrapData.fileName {
                                multipart.appendBodyPart(data: wrapData.data, name: wrapData.name, fileName: fileName, mimeType: mimeType)
                            } else {
                                multipart.appendBodyPart(data: wrapData.data, name: wrapData.name)
                            }
                        } else if wrapped is UploadFormFileURL {
                            let wrapFileURL = wrapped as! UploadFormFileURL
                            if let mimeType = wrapFileURL.mimeType, let fileName = wrapFileURL.fileName {
                                multipart.appendBodyPart(fileURL: wrapFileURL.fileURL, name: wrapFileURL.name, fileName: fileName, mimeType: mimeType)
                            } else {
                                multipart.appendBodyPart(fileURL: wrapFileURL.fileURL, name: wrapFileURL.name)
                            }
                        } else if wrapped is UploadFormStream {
                            let wrapStream = wrapped as! UploadFormStream
                            if let mimeType = wrapStream.mimeType, let fileName = wrapStream.fileName {
                                multipart.appendBodyPart(stream: wrapStream.stream, length: wrapStream.length, name: wrapStream.name, fileName: fileName, mimeType: mimeType)
                            } else {
                                fatalError("must have fileName & mimeType")
                            }
                        } else {
                            fatalError("do not use UploadWrap")
                        }
                    }
                    }, encodingCompletion: { encodingResult in
                        switch encodingResult {
                        case .success(let upload, _, _):
                            if let authProtocol = request as? ETRequestAuthProtocol {
//                                upload.delegate.credential = authProtocol.credential
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
                */
            }

            guard let req = jobReq else { return }
            
            if let authProtocol = request as? ETRequestAuthProtocol {
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
            fatalError("must implement ETRequestProtocol")
        }

    }
    
    func cancelRequest(_ request: ETRequest) {
        request.jobRequest?.cancel()
        self[request] = nil
    }
    
    func removeFromManager(_ request: ETRequest) {
        self[request] = nil
    }
    open func cancelAllRequests() {
        let dic = subRequests as NSDictionary
        let copyDic: NSMutableDictionary = dic.mutableCopy() as! NSMutableDictionary
        
        for (_, value) in copyDic {
            let request = value as! ETRequest
            cancelRequest(request)
        }
    }
    
    //MARK: private
      fileprivate func buildRequestUrl(_ request: ETRequest) -> String {
        if let requestProtocol = request as? ETRequestProtocol  {
            if requestProtocol.requestUrl.hasPrefix("http") {
                return requestProtocol.requestUrl
            }
            
            return "\(requestProtocol.baseUrl)\(requestProtocol.requestUrl)"
            
        } else {
            fatalError("must implement ETRequestProtocol")
        }
    }
}
