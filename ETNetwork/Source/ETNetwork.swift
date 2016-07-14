//
//  ETNetwork.swift
//  ETNetwork
//
//  Created by ethan on 15/11/30.
//  Copyright © 2015年 ethan. All rights reserved.
//

import Foundation
import Alamofire

///wrap the alamofire method
public enum ETRequestMethod {
    case Options, Get, Head, Post, Put, Patch, Delete, Trace, Connect
    
    var method: Alamofire.Method {
        switch self {
        case .Options:
            return Method.OPTIONS
        case .Get:
            return Method.GET
        case .Head:
            return Method.HEAD
        case .Post:
            return Method.POST
        case .Put:
            return Method.PUT
        case .Patch:
            return Method.PATCH
        case .Delete:
            return Method.DELETE
        case .Trace:
            return Method.TRACE
        case .Connect:
            return Method.CONNECT
            
        }
    }
}

///wrap the alamofire ParameterEncoding
public enum ETRequestParameterEncoding {
    case Url
    case UrlEncodedInURL
    case Json
    case PropertyList(NSPropertyListFormat, NSPropertyListWriteOptions)
    
    var encode: ParameterEncoding {
        switch self {
        case .Url:
            return ParameterEncoding.URL
        case .UrlEncodedInURL:
            return ParameterEncoding.URLEncodedInURL
        case .Json:
            return ParameterEncoding.JSON
        case .PropertyList(let format, let options):
            return ParameterEncoding.PropertyList(format, options)
        }
    }
}



public enum ETTaskType {
    case Data, Download, UploadFileData, UploadFileURL, UploadFormData
}

public enum ETResponseSerializer {
    case Data, String, Json, PropertyList
}


/**
 conform to custom your own NSURLRequest
 if you conform to this protocol, the ETRequestProtocol will be ignored
 */
public protocol ETRequestCustom {
    var customUrlRequest: NSURLRequest { get}
}

/**
 conform to custom your own request cache
 */
public protocol ETRequestCacheProtocol: class {
    var cacheSeconds: Int { get }
    var cacheVersion: UInt64 { get }
}

public extension ETRequestCacheProtocol {
    ///default value 0
    var cacheVersion: UInt64 { return 0 }
}

/**
 your subclass must conform this protocol
 */
public protocol ETRequestProtocol : class {
    var requestUrl: String { get }
    
    var taskType: ETTaskType { get }
    var baseUrl: String { get }
    var method: ETRequestMethod { get }
    var parameters:  [String: AnyObject]? { get }
    
    var headers: [String: String]? { get }
    var parameterEncoding: ETRequestParameterEncoding { get }
    var responseStringEncoding: NSStringEncoding { get }
    var responseJsonReadingOption: NSJSONReadingOptions { get }
    var responseSerializer: ETResponseSerializer { get }
}

/**
 make ETRequestProtocol some methed default and optional
 */
public extension ETRequestProtocol {
    var baseUrl: String { return ETNetworkConfig.sharedInstance.baseUrl }
    
    var parameters: [String: AnyObject]? { return nil }
    var headers: [String: String]? { return nil }
    var parameterEncoding: ETRequestParameterEncoding { return  .Json }
    var responseStringEncoding: NSStringEncoding { return NSUTF8StringEncoding }
    var responseJsonReadingOption: NSJSONReadingOptions { return .AllowFragments }
    var responseSerializer: ETResponseSerializer { return .Json }
}


public protocol ETRequestDownloadProtocol: class {
    ///DownloadTaskDelegate data is resumeData
    var resumeData: NSData? { get }
    ///the url that you want to save the file
    func downloadDestination() -> (NSURL, NSHTTPURLResponse) -> NSURL
}

public extension ETRequestDownloadProtocol {
    var resumeData: NSData? { return nil }
    func downloadDestination() -> (NSURL, NSHTTPURLResponse) -> NSURL {
        return ETRequest.suggestedDownloadDestination()
    }
}

public protocol ETRequestUploadProtocol: class {
    var fileURL: NSURL? { get }
    var fileData: NSData? { get }
    var formData: [UploadFormProtocol]? { get }
}


public extension ETRequestUploadProtocol {
    var fileURL: NSURL? { return nil }
    var fileData: NSData? { return nil }
    var formData: [UploadFormProtocol]? { return nil }
}


public protocol ETRequestAuthProtocol : class {
    var credential: NSURLCredential? { get }
}

extension ETRequestAuthProtocol {
    var credential: NSURLCredential? {
        return nil
    }
}

public protocol UploadFormProtocol : class {
    
}


public final class UploadFormData: UploadFormProtocol {
    var name: String
    var data: NSData
    var fileName: String?
    var mimeType: String?
    
    public init(name: String, data: NSData, fileName: String? = nil, mimeType: String? = nil) {
        self.name = name
        self.data = data
        self.fileName = fileName
        self.mimeType = mimeType
    }
    
}

public final class UploadFormFileURL: UploadFormProtocol {
    var name: String
    var fileURL: NSURL
    var fileName: String?
    var mimeType: String?
    
    public init(name: String,  fileURL: NSURL, fileName: String? = nil, mimeType: String? = nil) {
        self.name = name
        self.fileURL = fileURL
        self.fileName = fileName
        self.mimeType = mimeType
    }
    
}

public final class UploadFormStream: UploadFormProtocol {
    var name: String
    var stream: NSInputStream
    var length: UInt64
    var fileName: String?
    var mimeType: String?
 
    public init(name: String, stream: NSInputStream, length: UInt64, fileName: String? = nil, mimeType: String? = nil) {
        self.name = name
        self.stream = stream
        self.length = length
        self.fileName = fileName
        self.mimeType = mimeType
    }
}


//name easily
typealias JobRequest = Request
typealias JobManager = Manager