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
    private var requestDic: Dictionary<String, ETRequest> =  Dictionary<String, ETRequest>()
    
    public init() {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = Manager.defaultHTTPHeaders
        manager = Manager(configuration: configuration)
    }

    func addRequest(request: ETRequest) {
        if let subRequest = request as? ETRequestProtocol {
            let method = subRequest.method.method
            let headers = subRequest.headers
            let serializer = subRequest.responseSerializer
            let parameters = subRequest.parameters
            let encoding = subRequest.parameterEncoding.encode
            let req = manager.request(method, buildRequestUrl(request), parameters: parameters, encoding: encoding, headers: headers)
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
        } else {
            fatalError("must implement ETRequestProtocol")
        }

    }
    
    func cancelRequest(request: ETRequest) {
        
    }
    
    func cancelAllRequests(request: ETRequest) {
        
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
