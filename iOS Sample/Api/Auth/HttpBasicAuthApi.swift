//
//  PostApi.swift
//  iOS Sample
//
//  Created by ethan on 15/11/29.
//  Copyright © 2015年 ethan. All rights reserved.
//

import UIKit
import ETNetwork


class HttpBasicAuthApi: ETRequest {
    
    var bar: String
    init(bar: String) {
        self.bar = bar
        super.init()
    }
}

extension HttpBasicAuthApi: ETRequestProtocol {
        var headers: [String: String]? {
        return ["token": "YourCustomToken"]
    }
    var method: ETRequestMethod { return .Get }
    var taskType: ETTaskType { return .Data }
    var requestUrl: String { return "/basic-auth/user/passwd" }
    var parameters:  [String: AnyObject]? {
        return ["foo": bar]
    }
}

extension HttpBasicAuthApi: ETRequestAuthProtocol {
    var credential: NSURLCredential? {
        let user = "user"
        let password = "passwd"
        let credential = NSURLCredential(user: user, password: password, persistence: .ForSession)
        return credential
    }

}

