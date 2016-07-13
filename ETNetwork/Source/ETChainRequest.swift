//
//  ETChainRequest.swift
//  ETNetwork
//
//  Created by ethan on 15/11/4.
//  Copyright © 2015年 ethan. All rights reserved.
//


import Foundation


public class ETChainRequest {
    private var requests: [ETRequest] = []
    private var finishedTask = 0
    lazy var operationQueue: NSOperationQueue = {
        let operationQueue = NSOperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.suspended = true
        return operationQueue
    }()

    //FIXME: completion not right
    public var completion: ((error: NSError?) -> Void)?

    deinit {
        operationQueue.cancelAllOperations()
        operationQueue.suspended = false
        ETLog("\(self.dynamicType)  deinit")
    }

    public init() {

    }

    public func addRequest(req: ETRequest, completion: (AnyObject?, NSError?) -> Void) {
        requests.append(req)
        operationQueue.addOperationWithBlock { () -> Void in
            req.start()
            req.responseJson({ (json, error) -> Void in
                if error == nil {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        completion(json, error)
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

    public func start() {
        operationQueue.suspended = false
    }

    public func stop() {
        operationQueue.cancelAllOperations()
        for req in self.requests {
            req.cancel()
        }
        requests.removeAll()
    }
}

