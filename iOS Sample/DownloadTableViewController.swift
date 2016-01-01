//
//  DownloadTableViewController.swift
//  iOS Sample
//
//  Created by gengduo on 15/12/15.
//  Copyright © 2015年 ethan. All rights reserved.
//

import UIKit
import ETNetwork

class DownloadTableViewController: UITableViewController {

    var downloadRows: DownloadRows?
    var downloadApi: ETRequest?

    deinit {
        downloadApi?.cancel()

        print("\(self.dynamicType)  deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        guard let downloadRows = downloadRows else { fatalError("not set rows") }
        switch downloadRows {
        case .Download, .DownloadWithResumeData:
            downloadApi = GetDownloadApi(bar: "GetDownloadApi")
        }


        self.title = "\(downloadRows.description)"

        downloadApi?.start()
//        if let data = downloadApi?.cachedData {
//            print("cached data: \(data)")
//        }
        downloadApi?.progress({ (bytesRead, totalBytesRead, totalBytesExpectedToRead) -> Void in
            print("bytesRead: \(bytesRead), totalBytesRead: \(totalBytesRead), totalBytesExpectedToRead: \(totalBytesExpectedToRead)")
            print("percent: \(Float(totalBytesRead)/Float(totalBytesExpectedToRead))")
        }).responseData({ (data, error) -> Void in
            if (error != nil) {
                print("==========error: \(error)")
            } else {
                print("download successful")
//                print("==========data: \(data)")
            }
        })

        /*

        let tmpApi = GetDownloadApi(bar: "GetDownloadApi")
        tmpApi.start()

        tmpApi.progress({ (bytesRead, totalBytesRead, totalBytesExpectedToRead) -> Void in
            print("tmpApi bytesRead: \(bytesRead), totalBytesRead: \(totalBytesRead), totalBytesExpectedToRead: \(totalBytesExpectedToRead)")
            print("tmpApi percent: \(Float(totalBytesRead)/Float(totalBytesExpectedToRead))")
        }).responseData({ (data, error) -> Void in
            if (error != nil) {
                print("tmpApi ==========error: \(error)")
            } else {
                print("tmpApi download successful")
                //                print("==========data: \(data)")
            }
        })

        */

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
