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
    
    var data: Data?
    init(data: Data?) {
        self.data = data
        print("resumedata size: \(data?.count)")
        super.init()
    }
}

extension DownloadResumeDataApi: ETRequestProtocol {
    var method: ETRequestMethod { return .get }
    var taskType: ETTaskType { return .download }
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
//    func downloadDestination() -> (URL, HTTPURLResponse) -> URL {
//        return { temporaryURL, response -> URL in
//            let directoryURLs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
//            if !directoryURLs.isEmpty {
//                return directoryURLs[0].appendingPathComponent("mydownload.dmg")
//            }
//            
//            return temporaryURL
//        }
//    }
    
    var resumeData: Data? { return data }
}

