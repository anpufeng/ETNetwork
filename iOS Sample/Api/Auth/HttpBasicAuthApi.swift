//
//  PostApi.swift
//  iOS Sample
//
//  Created by ethan on 15/11/29.
//  Copyright © 2015年 ethan. All rights reserved.
//

import UIKit
import ETNetwork


class HttpBasicAuthApi: NetRequest {
    
    var bar: String
    init(bar: String) {
        self.bar = bar
        super.init()
    }
}

extension HttpBasicAuthApi: RequestProtocol {
        var headers: [String: String]? {
        return ["token": "YourCustomToken"]
    }
    var method: RequestMethod { return .get }
    var taskType: TaskType { return .data }
    var requestURL: String { return "/basic-auth/user/passwd" }
    var parameters:  [String: AnyObject]? {
        return ["foo": bar as AnyObject]
    }
}

extension HttpBasicAuthApi: RequestAuthProtocol {
    var credential: URLCredential? {
        let user = "user"
        let password = "passwd"
        let credential = URLCredential(user: user, password: password, persistence: .forSession)
        return credential
    }

}

