//
//  ETBatchRequest.swift
//  ETNetwork
//
//  Created by ethan on 15/11/4.
//  Copyright © 2015年 ethan. All rights reserved.
//

import Foundation

public class ETBatchRequest {
    private var requests: [ETRequest] = []
    private var finishedTask = 0
    lazy var operationQueue: NSOperationQueue = {
        let operationQueue = NSOperationQueue()
        operationQueue.maxConcurrentOperationCount = 3
        operationQueue.suspended = true
        return operationQueue
    }()

    private let seriQueue = dispatch_queue_create("batch_queue", nil)
    public var completion: ((error: NSError?) -> Void)?
    
    deinit {
        operationQueue.cancelAllOperations()
        operationQueue.suspended = false
        
       log("\(self.dynamicType)  deinit")
    }

    public init(requests: [ETRequest], maxConcurrent: Int = 3) {
        self.requests = requests
        self.operationQueue.maxConcurrentOperationCount = maxConcurrent

        for req in self.requests {
            req.needInOperationQueue = true
            _addRequest(req)
        }
    }

    private func _addRequest(req: ETRequest) {
        operationQueue.addOperationWithBlock { () -> Void in
            req.start()
            req.response({ (data, error) -> Void in
                if error == nil {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.finishedTask++
                        if self.finishedTask == self.requests.count {
                            self.completion?(error: nil)
                        }
                    })

                } else {
                    self.stop()
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.completion?(error: error)
                    })

                }
            })
        }
    }

    public func addRequest(req: ETRequest) {
        dispatch_async(seriQueue) {
            self.requests.append(req)
        }
        
        _addRequest(req)
    }

    public func start() {
        operationQueue.suspended = false
    }

    public func stop() {
        operationQueue.cancelAllOperations()
        for req in self.requests {
            req.cancel()
        }
        dispatch_async(seriQueue) { 
           self.requests.removeAll()
        }
    }
}
