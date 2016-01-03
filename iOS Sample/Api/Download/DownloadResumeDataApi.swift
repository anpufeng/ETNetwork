//
//  GetApi.swift
//  iOS Sample
//
//  Created by ethan on 15/11/18.
//  Copyright © 2015年 ethan. All rights reserved.
//

import UIKit
import ETNetwork

class DownloadResumeDataApi: ETRequest {
    
    var data: NSData?
    init(data: NSData?) {
        self.data = data
        super.init()
    }
}

extension DownloadResumeDataApi: ETRequestProtocol {
    var method: ETRequestMethod { return .Get }
    var taskType: ETTaskType { return .Download }
    var requestUrl: String { return "http://dldir1.qq.com/qqfile/QQforMac/QQ_V4.0.6.dmg" }
    var parameters:  [String: AnyObject]? {
        return nil
    }
    
   
}


extension DownloadResumeDataApi: ETRequestCacheProtocol {
    
    //cache
    var cacheSeconds: Int { return -1 }
}

extension DownloadResumeDataApi: ETRequestDownloadProtocol {
    func downloadDestination() -> (NSURL, NSHTTPURLResponse) -> NSURL {
        return { temporaryURL, response -> NSURL in
            let directoryURLs = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
            if !directoryURLs.isEmpty {
                return directoryURLs[0].URLByAppendingPathComponent("mydownload.dmg")
            }
            
            return temporaryURL
        }
    }
    
    var resumeData: NSData? { return data }
}

