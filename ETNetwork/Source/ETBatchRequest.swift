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

    public var completion: ((error: NSError?) -> Void)?
    
    deinit {
       ETLog("\(self.dynamicType)  deinit")
    }

    public init(requests: [ETRequest]) {
        self.requests = requests

        for req in self.requests {
            _addRequest(req)
        }
    }

    private func _addRequest(req: ETRequest) {
        operationQueue.addOperationWithBlock { () -> Void in
            req.start()
            req.response({ (data, error) -> Void in
                if error == nil {
                    self.finishedTask++
                    if self.finishedTask == self.requests.count {
                        self.completion?(error: nil)
                    }
                } else {
                    self.stop()
                    self.completion?(error: error)
                }
            })
        }
    }

    public func addRequest(req: ETRequest) {
        requests.append(req)
        _addRequest(req)
    }

    public func start() {
        operationQueue.suspended = false
    }

    public func stop() {
        operationQueue.cancelAllOperations()
        requests.removeAll()
    }
}
