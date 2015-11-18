//
//  ETManager.swift
//  ETNetwork
//
//  Created by ethan on 15/11/4.
//  Copyright © 2015年 ethan. All rights reserved.
//

import Foundation

public class ETManager: NSObject {
    
    public static let sharedInstance: ETManager = {
        return ETManager()
    }()
    
    private var manager: Manager
    private var config: ETNetworkConfig = ETNetworkConfig.sharedInstance
    private var requestDic: Dictionary<String, ETBaseRequest> =  Dictionary<String, ETBaseRequest>()
    
    internal override init()
    {
        manager = Manager.sharedInstance
        
    }

    func addRequest(request: ETBaseRequest) {
        if let subRequest = request as? ETBaseRequestProtocol {
            let method = subRequest.requestMethod().method
            let headers = subRequest.requestHeaders()
            let serializer = subRequest.requestSerializer()
            let params = subRequest.requestParams()
            let encoding = subRequest.requestParameterEncoding().encode
            let req = manager.request(method, self.buildRequestUrl(request), parameters: params, encoding: encoding, headers: headers)

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
                
            }
        } else {
            fatalError("must implement ETBaseRequestProtocol")
        }

    }
    
    func cancelRequest(request: ETBaseRequest) {
        
    }
    
    func cancelAllRequests(request: ETBaseRequest) {
        
    }
    
    //MARK: private
    //responseString
    private func handleRequestResult(request: ETBaseRequest, response: Response<String, NSError> ) {
        let req = response.request
        //guard request == req else { return }
        
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
    private func handleRequestResult(request: ETBaseRequest, response: Response<AnyObject, NSError> ) {
        
    }
    
    ///responseData
    private func handleRequestResult(request: ETBaseRequest, response: Response<NSData, NSError> ) {
        
    }
    
    private func buildRequestUrl(request: ETBaseRequest) -> String {
        if let subRequest = request as? ETBaseRequestProtocol  {
            if subRequest.requestUrl().hasPrefix("http") {
                return subRequest.requestUrl()
            }
            
            /*
            var baseUrl: String
            if let url  = subRequest.baseUrl?() {
                baseUrl = url
            } else {
                baseUrl = config.baseUrl
            }
            */
            
            return "\(subRequest.baseUrl)\(subRequest.requestUrl())"
            
        } else {
            fatalError("must implement ETBaseRequestProtocol")
        }
    }
}
