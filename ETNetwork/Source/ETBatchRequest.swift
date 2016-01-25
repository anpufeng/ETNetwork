//
//  ETBatchRequest.swift
//  ETNetwork
//
//  Created by ethan on 15/11/4.
//  Copyright © 2015年 ethan. All rights reserved.
//

import Foundation

public protocol ETBatchRequestDelegate {

}

public class ETBatchRequest {
    private var requests: [ETRequest] = []
    private var finishedTask = 0
    lazy var operationQueue: NSOperationQueue = {
        let operationQueue = NSOperationQueue()
        operationQueue.maxConcurrentOperationCount = 3
        operationQueue.suspended = true
        return operationQueue
    }()

    public init(requests: [ETRequest]) {
        self.requests = requests

        for req in self.requests {
            self.addRequest(req)
        }
    }

    public func addRequest(req: ETRequest) {
        self.requests.append(req)
        self.operationQueue.addOperationWithBlock { () -> Void in
            req.response({ (data, error) -> Void in
                if error == nil {
                    ETLog("finish one task")
                    self.finishedTask++
                    if self.finishedTask == self.requests.count {
                        ETLog("finish all task")
                    }
                } else {
                    //ERROR
                    print("request error: \(error)")
                    self.stop()
                }
            })
            req.start()

        }
    }

    public func start() {
        self.operationQueue.suspended = false
    }

    public func stop() {
        self.operationQueue.cancelAllOperations()
        self.requests.removeAll()
    }
}
