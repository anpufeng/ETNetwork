//
//  DownloadTableViewController.swift
//  iOS Sample
//
//  Created by gengduo on 15/12/15.
//  Copyright © 2015年 ethan. All rights reserved.
//

import UIKit
import ETNetwork

var shouldResume = false

class DownloadTableViewController: UITableViewController {

    @IBOutlet weak var readLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var processView: UIProgressView!
    var downloadRows: DownloadRows?
    var downloadApi: NetRequest?
    var manager: NetManager = NetManager(timeoutForRequest: 15)

    @IBOutlet weak var resumeBtn: UIButton!
    deinit {
        manager.cancelAllRequests()

        print("\(type(of: self))  deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        downloadRequest()

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(DownloadTableViewController.refresh), for: .valueChanged)
    }
    
    class func saveLastData(_ data: Data?) {
        if shouldResume {
            guard let data = data else {
                UserDefaults.standard.set(nil, forKey: "resumeData")
                return
            }
            
            print("savelastData: -----------");
            UserDefaults.standard.set(data, forKey: "resumeData")
        }
    }
    class func lastData() -> Data? {
        return UserDefaults.standard.data(forKey: "resumeData")
    }

    @IBAction func refresh() {
        refreshControl?.beginRefreshing()
        DownloadTableViewController.saveLastData(nil)
        downloadRequest()
        refreshControl?.endRefreshing()
    }

    func downloadRequest() {
        guard let downloadRows = downloadRows else { fatalError("not set rows") }
        downloadApi?.cancel()
        switch downloadRows {
        case .download:
            downloadApi = GetDownloadApi(bar: "GetDownloadApi")
            shouldResume = false
        case .downloadWithResumeData:
            downloadApi = DownloadResumeDataApi(data: DownloadTableViewController.lastData())
            shouldResume = true
        }


        title = "\(downloadRows.description)"
        downloadApi?.start(manager, ignoreCache: true)

        //        if let data = downloadApi?.cachedData {
        //            print("cached data: \(data)")
        //        }
        downloadApi?.progress({ [weak self] (totalBytesRead, totalBytesExpectedToRead) -> Void in
            guard let strongSelf = self else { return }
            print("totalBytesRead: \(totalBytesRead), totalBytesExpectedToRead: \(totalBytesExpectedToRead)")
            let percent = Float(totalBytesRead)/Float(totalBytesExpectedToRead)
            print("percent: \(percent)")
            DispatchQueue.main.async(execute: { () -> Void in
                strongSelf.processView.progress = percent
                let read = String(format: "%.2f", Float(totalBytesRead)/1024)
                let total = String(format: "%.2f", Float(totalBytesExpectedToRead)/1024)
                strongSelf.readLabel.text = "read: \(read) KB"
                strongSelf.totalLabel.text = "total: \(total) KB"
            })
           
        }).responseData({ (data, error) -> Void in
            print("data: \(data) size: \(data?.count), error: \(error)")
            DownloadTableViewController.saveLastData(data)
        }).httpResponse({ (httpResponse, error) -> Void in
            print("httpResponse \(httpResponse), error: \(error)")
        })
    }


    @IBAction func responseToResumeBtn(_ sender: UIButton) {
        if sender.isSelected {
            downloadApi?.resume()
            sender.isSelected = false
        } else {
            downloadApi?.suspend()
            sender.isSelected = true
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
/*
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }
*/

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
