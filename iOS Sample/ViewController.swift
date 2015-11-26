//
//  ViewController.swift
//  iOS Sample
//
//  Created by ethan on 15/11/4.
//  Copyright © 2015年 ethan. All rights reserved.
//

import UIKit
import ETNetwork


class Log {
    class func msg(message: String,
        functionName:  String = __FUNCTION__, fileNameWithPath: String = __FILE__, lineNumber: Int = __LINE__ ) {
            // In the default arguments to this function:
            // 1) If I use a String type, the macros (e.g., __LINE__) don't expand at run time.
            //  "\(__FUNCTION__)\(__FILE__)\(__LINE__)"
            // 2) A tuple type, like,
            // typealias SMLogFuncDetails = (String, String, Int)
            //  SMLogFuncDetails = (__FUNCTION__, __FILE__, __LINE__)
            //  doesn't work either.
            // 3) This String = __FUNCTION__ + __FILE__
            //  also doesn't work.
            
            let path = fileNameWithPath as NSString
            var fileNameWithoutPath = path.lastPathComponent
            
            #if DEBUG
                let output = "\(NSDate()): \(message) [\(functionName) in \(fileNameWithoutPath), line \(lineNumber)]"
                println(output)
            #endif
    }
}


class ViewController: UIViewController, ETRequestDelegate {
    var getApi: GetApi = GetApi(bar: "bar")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if let json = getApi.cachedJson {
            // print("==========requestFinished res json: \(json)")
        }
        
        getApi.delegate = self
        getApi.start()
        etLogEnable = false
        ETLog("hello \(getApi)")
        
        /*
        if let json = getApi.cachedData {
            print("==========requestFinished res json: \(json)")
        } else {
            getApi.delegate = self
            getApi.start()
        }
        
        getApi.start()
        getApi.responseJson({ (json, error) -> Void in
            print("==========requestFinished res json: \(json)")
        }).responseStr { (str, error) -> Void in
            print("==========requestFinished res string: \(str)")
        }
        
       
        getApi = GetApi(bar: "bar22222222")
        getApi.delegate = self
        getApi.start()
        getApi.responseJson({ (json, error) -> Void in
            print("==========requestFinished res json: \(json)")
        }).responseStr { (str, error) -> Void in
            print("==========requestFinished res string: \(str)")
        }
*/
    }
    
    ///MARK
    func requestFinished(request: ETRequest) {
        if request === getApi {
            
            request.responseJson({ (json, error) -> Void in
             print("==========requestFinished res json: \(json)")
            })
        }

    }
    func requestFailed(request: ETRequest) {
        if request === getApi {
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

