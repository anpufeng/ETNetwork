//
//  ViewController.swift
//  iOS Sample
//
//  Created by ethan on 15/11/4.
//  Copyright © 2015年 ethan. All rights reserved.
//

import UIKit
import ETNetwork

class ViewController: UIViewController, ETRequestDelegate {
    var getApi: GetApi = GetApi(bar: "bar")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if let _ = getApi.cachedJson {
            // print("==========requestFinished res json: \(json)")
        }
        
        getApi.delegate = self
        getApi.start()
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

