//
//  UploadTableViewController.swift
//  iOS Sample
//
//  Created by gengduo on 15/12/15.
//  Copyright © 2015年 ethan. All rights reserved.
//

import UIKit
import ETNetwork

class UploadTableViewController: UITableViewController {

    @IBOutlet weak var writeLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var processView: UIProgressView!
    var uploadRows: UploadRows?
    var uploadApi: ETRequest?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()


        guard let uploadRows = uploadRows else { fatalError("not set rows") }
        switch uploadRows {
        case .UploadFile:
            let fileURL = NSBundle.mainBundle().URLForResource("upload", withExtension: "png")
            uploadApi = UploadFileApi(fileURL: fileURL!)
        case .UploadData:
            if let path = NSBundle.mainBundle().pathForResource("sample", ofType: "json") {
                if let data = NSData(contentsOfFile: path) {
                    uploadApi = UploadDataApi(data: data)
                }

            }

        case .UploadStream:
            if let jsonPath = NSBundle.mainBundle().pathForResource("sample", ofType: "json"), imgPath = NSBundle.mainBundle().pathForResource("upload", ofType: "png"){
                if let jsonData = NSData(contentsOfFile: jsonPath), imgData = NSData(contentsOfFile: imgPath) {
                    uploadApi = UploadStreamApi(jsonData: jsonData, imgData: imgData)
                }

            }
        }

        self.title = "\(uploadRows.description)"


        guard let uploadApi = uploadApi else { fatalError("request nil") }

        uploadApi.start()
        uploadApi.formDataencodingError { (error) -> Void in
            print("encoding error: \(error)")
        }.progress({ [weak self] (bytesWrite, totalBytesWrite, totalBytesExpectedToWrite) -> Void in
            print("bytesWrite: \(bytesWrite), totalBytesWrite: \(totalBytesWrite), totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
            print("percent: \(100 * Float(totalBytesWrite)/Float(totalBytesExpectedToWrite))")
            
            let percent = Float(totalBytesWrite)/Float(totalBytesExpectedToWrite)
            guard let strongSelf = self else { return }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                strongSelf.processView.progress = percent
                let read = String(format: "%.2f", Float(totalBytesWrite)/1024)
                let total = String(format: "%.2f", Float(totalBytesExpectedToWrite)/1024)
                strongSelf.writeLabel.text = "read: \(read) KB"
                strongSelf.totalLabel.text = "total: \(total) KB"
            })
        }).responseJson({ (json, error) -> Void in
            if (error != nil) {
                print("==========error: \(error)")
            } else {
                print(self.uploadApi.debugDescription)
                print("==========json: \(json)")
            }
        })
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
