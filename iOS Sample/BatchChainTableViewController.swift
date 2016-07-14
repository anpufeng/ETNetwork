//
//  BatchChainTableViewController.swift
//  iOS Sample
//
//  Created by gengduo on 16/1/28.
//  Copyright © 2016年 ethan. All rights reserved.
//

import UIKit
import ETNetwork

class BatchChainTableViewController: UITableViewController {
    var bcRows: BatchChainRows?
    var chainApi: ETChainRequest?
    var batchApi: ETBatchRequest?
    deinit {
        chainApi?.stop()
        batchApi?.stop()
        print("\(self.dynamicType)  deinit")
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        bcRequest()
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(BatchChainTableViewController.refresh), forControlEvents: .ValueChanged)
    }

    @IBAction func refresh() {
        refreshControl?.beginRefreshing()
        DownloadTableViewController.saveLastData(nil)
        bcRequest()
        refreshControl?.endRefreshing()
    }


    func bcRequest() {
        guard let bcRows = bcRows else { fatalError("not set rows") }
        switch bcRows {
        case .Chain:
            let one = GetApi(bar: "GetApi")
            let two = PostApi(bar: "PostApi")
            let three = PutApi(bar: "PutApi")
            let four = DeleteApi(bar: "DeleteApi")

            chainApi = ETChainRequest()
            chainApi?.addRequest(one) { (json, error) -> Void in
                print("++++++ 1 finished")
                self.chainApi?.addRequest(two) { (json, error) -> Void in
                    print("++++++ 2 finished")
                    self.chainApi?.addRequest(three) { (json, error) -> Void in
                        print("++++++ 3 finished")
                        self.chainApi?.addRequest(four) { (json, error) -> Void in
                            print("++++++ 4 finished")
                        }
                    }
                }
            }

            chainApi?.completion = { error in
                if let error = error {
                    print("chain request failure : \(error)")
                } else {
                    print("chain request success")
                }
            }
            chainApi?.start()
        case .Batch:

            let one = GetApi(bar: "GetApi")
            let two = PostApi(bar: "PostApi")
            let three = PutApi(bar: "PutApi")
            let four = DeleteApi(bar: "DeleteApi")
            let five = GetDownloadApi(bar: "GetDownloadApi")
            

            batchApi = ETBatchRequest(requests: [one, two, three, four, five])
            batchApi?.start()
            one.responseJson { (json, error) -> Void in
                if (error != nil) {
                    print("==========error: \(error)")
                } else {
                    print("one finished: \(json)")
                }
            }


            two.responseJson { (json, error) -> Void in
                if (error != nil) {
                    print("==========error: \(error)")
                } else {
                    print("two finished")
                }
            }

            three.responseJson { (json, error) -> Void in
                if (error != nil) {
                    print("==========error: \(error)")
                } else {
                    print("three finished: \(json)")
                }
            }

            four.responseJson { (json, error) -> Void in
                if (error != nil) {
                    print("==========error: \(error)")
                } else {
                    print("four finished: \(json)")
                }
            }

            five.response { (data, error) -> Void in
                if (error != nil) {
                    print("==========error: \(error)")
                } else {
                    print("five finished")
                }
                }.progress({ (bytesRead, totalBytesRead, totalBytesExpectedToRead) -> Void in
                    print("bytesRead: \(bytesRead), totalBytesRead: \(totalBytesRead), totalBytesExpectedToRead: \(totalBytesExpectedToRead)")
                    let percent = Float(totalBytesRead)/Float(totalBytesExpectedToRead)
                    print("percent: \(percent)")
                })

            batchApi?.completion = { error in
                if let error = error {
                    print("batch request failure : \(error)")
                } else {
                    print("batch request success")
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
