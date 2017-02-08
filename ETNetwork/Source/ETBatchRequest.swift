//
//  ETBatchRequest.swift
//  ETNetwork
//
//  Created by ethan on 15/11/4.
//  Copyright © 2015年 ethan. All rights reserved.
//

import Foundation

open class ETBatchRequest {
    fileprivate var requests: [ETRequest] = []
    fileprivate var finishedTask = 0
    lazy var operationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 3
        operationQueue.isSuspended = true
        return operationQueue
    }()

    fileprivate let seriQueue = DispatchQueue(label: "batch_queue", attributes: [])
    open var completion: ((_ error: Error?) -> Void)?
    
    deinit {
        operationQueue.cancelAllOperations()
        operationQueue.isSuspended = false
        
       log("\(type(of: self))  deinit")
    }

    public init(requests: [ETRequest], maxConcurrent: Int = 3) {
        self.requests = requests
        self.operationQueue.maxConcurrentOperationCount = maxConcurrent

        for req in self.requests {
            req.needInOperationQueue = true
            _addRequest(req)
        }
    }

    fileprivate func _addRequest(_ req: ETRequest) {
        operationQueue.addOperation { () -> Void in
            req.start()
            req.responseData({ (data, error) -> Void in
                if error == nil {
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.finishedTask += 1
                        if self.finishedTask == self.requests.count {
                            self.completion?(nil)
                        }
                    })

                } else {
                    self.stop()
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.completion?(error)
                    })

                }
            })
        }
    }

    open func addRequest(_ req: ETRequest) {
        seriQueue.async {
            self.requests.append(req)
        }
        
        _addRequest(req)
    }

    open func start() {
        operationQueue.isSuspended = false
    }

    open func stop() {
        operationQueue.cancelAllOperations()
        for req in self.requests {
            req.cancel()
        }
        seriQueue.async { 
           self.requests.removeAll()
        }
    }
}
