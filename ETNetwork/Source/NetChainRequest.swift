//
//  NetChainRequest.swift
//  ETNetwork
//
//  Created by ethan on 15/11/4.
//  Copyright © 2015年 ethan. All rights reserved.
//


import Foundation


open class NetChainRequest {
    fileprivate var requests: [NetRequest] = []
    fileprivate var finishedTask = 0
    fileprivate let seriQueue = DispatchQueue(label: "NetChainRequest")
    lazy var operationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.isSuspended = true
        return operationQueue
    }()

    //FIXME: completion not right
    open var completion: ((_ error: Error?) -> Void)?

    deinit {
        operationQueue.cancelAllOperations()
        operationQueue.isSuspended = false
        log("\(type(of: self))  deinit")
    }

    public init() {

    }

    open func addRequest(_ req: NetRequest, completion: @escaping (Any?, Error?) -> Void) {
        seriQueue.sync {
            requests.append(req)
        }
        
        operationQueue.addOperation { () -> Void in
            req.start()
            req.responseJSON({ (json, error) -> Void in
                if error == nil {
                    DispatchQueue.main.async(execute: { () -> Void in
                        completion(json, error)
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

    open func start() {
        operationQueue.isSuspended = false
    }

    open func stop() {
        operationQueue.cancelAllOperations()
        for req in self.requests {
            req.cancel()
        }
        
        seriQueue.sync {
            requests.removeAll()
        }
        
    }
}

