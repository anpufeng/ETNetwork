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
    case options, get, head, post, put, patch, delete, trace, connect
    
    var method: Alamofire.HTTPMethod {
        switch self {
        case .options:
            return .options
        case .get:
            return .get
        case .head:
            return .head
        case .post:
            return .post
        case .put:
            return .put
        case .patch:
            return .patch
        case .delete:
            return .delete
        case .trace:
            return .trace
        case .connect:
            return .connect
            
        }
    }
}

///wrap the alamofire ParameterEncoding
public enum ETRequestParameterEncoding {
    case url
    case json
    case propertyList(PropertyListSerialization.PropertyListFormat, PropertyListSerialization.WriteOptions)
    
    var encode: ParameterEncoding {
        switch self {
        case .url:
            return URLEncoding.default
        case .json:
            return JSONEncoding.default
        case .propertyList(let format, let options):
            return PropertyListEncoding(format: format, options: options)
        }
    }
}



public enum ETTaskType {
    case data, download, uploadFileData, uploadFileURL, uploadFormData
}

public enum ETResponseSerializer {
    case data, string, json, propertyList
}


/**
 conform to custom your own NSURLRequest
 if you conform to this protocol, the ETRequestProtocol will be ignored
 */
public protocol ETRequestCustom {
    var customUrlRequest: URLRequest { get }
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
    var responseStringEncoding: String.Encoding { get }
    var responseJsonReadingOption: JSONSerialization.ReadingOptions { get }
    var responseSerializer: ETResponseSerializer { get }
}

/**
 make ETRequestProtocol some methed default and optional
 */
public extension ETRequestProtocol {
    var baseUrl: String { return ETNetworkConfig.sharedInstance.baseUrl }
    
    var parameters: [String: AnyObject]? { return nil }
    var headers: [String: String]? { return nil }
    var parameterEncoding: ETRequestParameterEncoding { return  .json }
    var responseStringEncoding: String.Encoding { return String.Encoding.utf8 }
    var responseJsonReadingOption: JSONSerialization.ReadingOptions { return .allowFragments }
    var responseSerializer: ETResponseSerializer { return .json }
}


public protocol ETRequestDownloadProtocol: class {
    ///DownloadTaskDelegate data is resumeData
    var resumeData: Data? { get }
    ///the url that you want to save the file
    
    func downloadDestination() -> (URL, HTTPURLResponse) -> (destinationURL: URL, options: Alamofire.DownloadRequest.DownloadOptions)
}

public extension ETRequestDownloadProtocol {
    var resumeData: Data? { return nil }
    func downloadDestination() -> (URL, HTTPURLResponse) -> (destinationURL: URL, options: Alamofire.DownloadRequest.DownloadOptions) {
        return ETRequest.suggestedDownloadDestination()
    }
}

public protocol ETRequestUploadProtocol: class {
    var fileURL: URL? { get }
    var fileData: Data? { get }
    var formData: [UploadFormProtocol]? { get }
}


public extension ETRequestUploadProtocol {
    var fileURL: URL? { return nil }
    var fileData: Data? { return nil }
    var formData: [UploadFormProtocol]? { return nil }
}


public protocol ETRequestAuthProtocol : class {
    var credential: URLCredential? { get }
}

extension ETRequestAuthProtocol {
    var credential: URLCredential? {
        return nil
    }
}

public protocol UploadFormProtocol : class {
    
}


public final class UploadFormData: UploadFormProtocol {
    var name: String
    var data: Data
    var fileName: String?
    var mimeType: String?
    
    public init(name: String, data: Data, fileName: String? = nil, mimeType: String? = nil) {
        self.name = name
        self.data = data
        self.fileName = fileName
        self.mimeType = mimeType
    }
    
}

public final class UploadFormFileURL: UploadFormProtocol {
    var name: String
    var fileURL: URL
    var fileName: String?
    var mimeType: String?
    
    public init(name: String,  fileURL: URL, fileName: String? = nil, mimeType: String? = nil) {
        self.name = name
        self.fileURL = fileURL
        self.fileName = fileName
        self.mimeType = mimeType
    }
    
}

public final class UploadFormStream: UploadFormProtocol {
    var name: String
    var stream: InputStream
    var length: UInt64
    var fileName: String?
    var mimeType: String?
 
    public init(name: String, stream: InputStream, length: UInt64, fileName: String? = nil, mimeType: String? = nil) {
        self.name = name
        self.stream = stream
        self.length = length
        self.fileName = fileName
        self.mimeType = mimeType
    }
}


//name easily
typealias JobRequest = Alamofire.Request
typealias JobManager = Alamofire.SessionManager
