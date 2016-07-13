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
    
    private let jobManager: JobManager
    private var subRequests: [Int: ETRequest] = [:]
    private let concurrentQueue = dispatch_queue_create(nil, DISPATCH_QUEUE_CONCURRENT)
    
    private struct AssociatedKey {
        static var inneKey = "etrequest"
    }
    
    subscript(request: ETRequest) -> ETRequest? {
        get {
            var req: ETRequest?
            guard let identifier = request.requestIdentifier else { return req }
            dispatch_sync(concurrentQueue) {
                req = self.subRequests[identifier]
            }
            
            return req
        }
        
        set {
            guard let identifier = request.requestIdentifier else { return }
            dispatch_barrier_async(concurrentQueue) {
                self.subRequests[identifier] = newValue
            }
        }
    }
    public convenience init() {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = Manager.defaultHTTPHeaders
        configuration.timeoutIntervalForRequest = 15
        self.init(configuration: configuration)
    }

    public convenience init(timeoutForRequest: NSTimeInterval) {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = Manager.defaultHTTPHeaders
        configuration.timeoutIntervalForRequest = timeoutForRequest
        self.init(configuration: configuration)
    }

    public init(configuration: NSURLSessionConfiguration) {
        jobManager = JobManager(configuration: configuration)
        jobManager.delegate.taskDidComplete = { [weak self] (session, task, error) -> Void in
            //use the default process before our job
            if let strongSelf = self {
                if let delegate = strongSelf.jobManager.delegate[task] {
                    delegate.URLSession(session, task: task, didCompleteWithError: error)
                }

                //additional job
                let request  = objc_getAssociatedObject(task, &AssociatedKey.inneKey) as? ETRequest
                if let request = request {
                    ETLog(request.jobRequest.debugDescription)
                    if let _ = error {
                        request.delegate?.requestFailed(request)
                    } else {
                        request.delegate?.requestFinished(request)
                        request.saveResponseToCacheFile()
                    }

                    strongSelf.cancelRequest(request)
                    strongSelf[request] = nil
                } else {
                    ETLog("objc_getAssociatedObject fail ")
                }
            }
        }
    }

    deinit {
        ETLog("\(self.dynamicType ) deinit")
    }

    func addRequest(request: ETRequest) {
        if let requestProtocol = request as? ETRequestProtocol {
            let method = requestProtocol.method.method
            let headers = requestProtocol.headers
            let serializer = requestProtocol.responseSerializer
            let parameters = requestProtocol.parameters
            let encoding = requestProtocol.parameterEncoding.encode
            
            var jobReq: Request?
            switch requestProtocol.taskType {
            case .Data:
                jobReq = jobManager.request(method, buildRequestUrl(request), parameters: parameters, encoding: encoding, headers: headers)
            case .Download:
                guard let downloadProtocol = request as? ETRequestDownloadProtocol else { fatalError("not implement ETRequestDownloadProtocol") }
                 let destination = downloadProtocol.downloadDestination()
                if let resumeData = downloadProtocol.resumeData {
                    jobReq = jobManager.download(resumeData, destination: destination)
                } else {
                    jobReq = jobManager.download(method, buildRequestUrl(request), parameters: parameters, encoding: encoding, headers: headers, destination: destination)
                }

            case .UploadFileURL:
                guard let uploadProtocol = request as? ETRequestUploadProtocol else { fatalError("not implement ETREquestUploadProtocol") }
                guard let fileURL = uploadProtocol.fileURL else { fatalError("must return fileURL") }
                jobReq = jobManager.upload(method, buildRequestUrl(request), headers:headers, file: fileURL)
            case .UploadFileData:
                guard let uploadProtocol = request as? ETRequestUploadProtocol else { fatalError("not implement ETREquestUploadProtocol") }
                guard let fileData = uploadProtocol.fileData else { fatalError("must return fileData") }
                jobReq = jobManager.upload(method, buildRequestUrl(request), headers:headers, data: fileData)
            case .UploadFormData:
                guard let uploadProtocol = request as? ETRequestUploadProtocol else { fatalError("not implement ETREquestUploadProtocol") }
                guard let formData = uploadProtocol.formData else { fatalError("must return formdata") }
                jobManager.upload(method, buildRequestUrl(request), multipartFormData: { multipart in
                    for wrapped in formData {
                        if wrapped is UploadFormData {
                            let wrapData = wrapped as! UploadFormData
                            if let mimeType = wrapData.mimeType, fileName = wrapData.fileName {
                                multipart.appendBodyPart(data: wrapData.data, name: wrapData.name, fileName: fileName, mimeType: mimeType)
                            } else {
                                multipart.appendBodyPart(data: wrapData.data, name: wrapData.name)
                            }
                            
                        } else if wrapped is UploadFormFileURL {
                            let wrapFileURL = wrapped as! UploadFormFileURL
                            if let mimeType = wrapFileURL.mimeType, fileName = wrapFileURL.fileName {
                                multipart.appendBodyPart(fileURL: wrapFileURL.fileURL, name: wrapFileURL.name, fileName: fileName, mimeType: mimeType)
                            } else {
                                multipart.appendBodyPart(fileURL: wrapFileURL.fileURL, name: wrapFileURL.name)
                            }
                        } else if wrapped is UploadFormStream {
                            let wrapStream = wrapped as! UploadFormStream
                            if let mimeType = wrapStream.mimeType, fileName = wrapStream.fileName {
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
                        case .Success(let upload, _, _):
                            if let authProtocol = request as? ETRequestAuthProtocol {
                                upload.delegate.credential = authProtocol.credential
                            }
                            objc_setAssociatedObject(upload.task, &AssociatedKey.inneKey, request, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
                            request.jobRequest = upload
                            self[request] = request
                            request.manager = self
                            request.operationQueue.suspended = false;
                            
                        case .Failure(let encodingError):
                            request.formDataEncodingErrorCompletion?(encodingError)
                        }
                })
            }

            guard let req = jobReq else { return }
            
            if let authProtocol = request as? ETRequestAuthProtocol {
                req.delegate.credential = authProtocol.credential
            }
            
            objc_setAssociatedObject(req.task, &AssociatedKey.inneKey, request, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
            request.jobRequest = req
            if request.needInOperationQueue {
                request.operationQueue.suspended = false
            }
            self[request] = request
            request.manager = self
        } else {
            fatalError("must implement ETRequestProtocol")
        }

    }
    
    func cancelRequest(request: ETRequest) {
        request.jobRequest?.cancel()
    }
    
    public func cancelAllRequests() {
        let dic = subRequests as NSDictionary
        let copyDic: NSMutableDictionary = dic.mutableCopy() as! NSMutableDictionary
        
        for (_, value) in copyDic {
            let request = value as! ETRequest
            cancelRequest(request)
        }
    }
    
    //MARK: private
      private func buildRequestUrl(request: ETRequest) -> String {
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
