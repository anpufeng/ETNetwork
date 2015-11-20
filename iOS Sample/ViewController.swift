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
        
        getApi.delegate = self
        getApi.start()
    }
    
    ///MARK
    func requestFinished(request: ETBaseRequest) {
        if request === getApi {
             print("==========requestFinished res json: \(request.responseJson)")
        }

    }
    func requestFailed(request: ETBaseRequest) {
        if request === getApi {
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

