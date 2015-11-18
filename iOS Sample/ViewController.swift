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
    
    func requestFinished(request: ETBaseRequest) {
        
    }
    func requestFailed(request: ETBaseRequest) {
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

