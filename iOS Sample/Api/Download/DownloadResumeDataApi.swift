//
//  GetApi.swift
//  iOS Sample
//
//  Created by ethan on 15/11/18.
//  Copyright © 2015年 ethan. All rights reserved.
//

import UIKit
import ETNetwork

class DownloadResumeDataApi: NetRequest {
    
    var data: Data?
    init(data: Data?) {
        self.data = data
        print("resumedata size: \(data?.count)")
        super.init()
    }
}

extension DownloadResumeDataApi: RequestProtocol {
    var method: RequestMethod { return .get }
    var taskType: TaskType { return .download }
    //http://dldir1.qq.com/qqfile/QQforMac/QQ_V4.0.6.dmg
    //http://ftp-apk.pconline.com.cn/b5cb691afcce3906dc11602df610f212/pub/download/201010/freewifi_2232_0909.apk
    var requestURL: String { return "http://ftp-apk.pconline.com.cn/b5cb691afcce3906dc11602df610f212/pub/download/201010/freewifi_2232_0909.apk" }
    var parameters:  [String: AnyObject]? {
        return nil
    }
    
   
}


extension DownloadResumeDataApi: RequestCacheProtocol {
    
    //cache
    var cacheSeconds: Int { return -1 }
}

extension DownloadResumeDataApi: RequestDownloadProtocol {
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

