//
//  ETManager.swift
//  ETNetwork
//
//  Created by ethan on 15/11/4.
//  Copyright © 2015年 ethan. All rights reserved.
//

import Foundation

class ETManager: NSObject {
    private var manager: Manager
    private var config: ETNetworkConfig = ETNetworkConfig.sharedInstance
    private var requestDic: Dictionary<String, ETBaseRequest> =  Dictionary<String, ETBaseRequest>()
    
    internal override init()
    {
        manager = Manager.init()
        
    }

    func addRequest(request: ETBaseRequest) {
        if let subRequest = request.child {
            let method = subRequest.requestMethod()

            let request = manager.request(.GET, self.buildRequestUrl(request), parameters: nil, encoding: .JSON, headers: nil)
            request.responseJSON(completionHandler: { response  -> Void in
                
            })
            
//            switch method {
//            case .Get
//                
//            }
        } else {
            fatalError("must implement ETBaseRequestProtocol")
        }

    }
    
    func cancelRequest(request: ETBaseRequest) {
        
    }
    
    func cancelAllRequests(request: ETBaseRequest) {
        
    }
    
    //MARK: private
    private func buildRequestUrl(request: ETBaseRequest) -> String {
        if let subRequest = request.child {
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
