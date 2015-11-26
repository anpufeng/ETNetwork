//
//  ETManager.swift
//  ETNetwork
//
//  Created by ethan on 15/11/4.
//  Copyright © 2015年 ethan. All rights reserved.
//

import Foundation


public class ETManager {
    
    public static let sharedInstance: ETManager = {
        return ETManager()
    }()
    
    private var manager: Manager
    private var subdRequest: [Int: ETRequest] = [:]
    private let subdRequestQueue = dispatch_queue_create(nil, DISPATCH_QUEUE_CONCURRENT)
    
    private struct AssociatedKey {
        static var inneKey = "etrequest"
    }
    
    subscript(request: ETRequest) -> ETRequest? {
        get {
            var req: ETRequest?
            guard let identifier = request.requestIdentifier else { return req }
            dispatch_sync(subdRequestQueue) {
                req = self.subdRequest[identifier]
            }
            
            return req
        }
        
        set {
            guard let identifier = request.requestIdentifier else { return }
            dispatch_barrier_async(subdRequestQueue) {
                self.subdRequest[identifier] = newValue
            }
        }
    }
    
    public init() {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = Manager.defaultHTTPHeaders
        manager = Manager(configuration: configuration)
        manager.delegate.taskDidComplete = { (session, sessionTask, error) -> Void in
            //TODO remove the request in subRequest
            let request  = objc_getAssociatedObject(sessionTask, &AssociatedKey.inneKey) as? ETRequest
            if let request = request {
                print("got you \(request)")
            } else {
                print("faile ")
            }
        }

    }

    func addRequest(request: ETRequest) {
        if let subRequest = request as? ETRequestProtocol {
            let method = subRequest.method.method
            let headers = subRequest.headers
            let serializer = subRequest.responseSerializer
            let parameters = subRequest.parameters
            let encoding = subRequest.parameterEncoding.encode
            let req = manager.request(method, buildRequestUrl(request), parameters: parameters, encoding: encoding, headers: headers)
            objc_setAssociatedObject(req.task, &AssociatedKey.inneKey, request, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            request.request = req

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
            
            //add request dictionary
            self[request] = request
            
        } else {
            fatalError("must implement ETRequestProtocol")
        }

    }
    
    func cancelRequest(request: ETRequest) {
        guard let request = self[request] else { return }
        
        request.request?.cancel()
        guard  let requestIdentifier = request.requestIdentifier else { return }
        subdRequest.removeValueForKey(requestIdentifier)
    }
    
    func cancelAllRequests() {
        for (_, value) in subdRequest {
            value.request?.cancel()
        }
        
        subdRequest.removeAll()
    }
    
    func removeRequest(request: ETRequest) {
        
    }
    
    //MARK: private
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
    
    private func buildRequestUrl(request: ETRequest) -> String {
        if let subRequest = request as? ETRequestProtocol  {
            if subRequest.requestUrl.hasPrefix("http") {
                return subRequest.requestUrl
            }
            
            /*
            var baseUrl: String
            if let url  = subRequest.baseUrl?() {
                baseUrl = url
            } else {
                baseUrl = config.baseUrl
            }
            */
            
            return "\(subRequest.baseUrl)\(subRequest.requestUrl)"
            
        } else {
            fatalError("must implement ETRequestProtocol")
        }
    }
}
