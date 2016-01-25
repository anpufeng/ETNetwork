//
//  BasicDataTableViewController.swift
//  iOS Sample
//
//  Created by ethan on 15/11/28.
//  Copyright © 2015年 ethan. All rights reserved.
//

import UIKit
import ETNetwork

class DataTableViewController: UITableViewController {
    @IBOutlet weak var bodyCell: UITableViewCell!
    @IBOutlet weak var headerCell: UITableViewCell!
    @IBOutlet weak var cacheSwitch: UISwitch!
    var dataRows: DataRows?
    var dataApi: ETRequest?

    deinit {
        dataApi?.cancel()
        print("\(self.dynamicType)  deinit")

    }
    override func awakeFromNib() {
        super.awakeFromNib()

    }

    @IBAction func refresh() {
        refreshControl?.beginRefreshing()
        self.dataRequest()
        self.refreshControl?.endRefreshing()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        self.dataRequest()

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: "refresh", forControlEvents: .ValueChanged)
    }

    func dataRequest() {
        guard let dataRows = dataRows else { fatalError("not set rows") }
        dataApi?.cancel()
        switch dataRows {
        case .Get:
            dataApi = GetApi(bar: "GetApi")
        case .Post:
            dataApi = PostApi(bar: "PostApi")
        case .Put:
            dataApi = PutApi(bar: "PutApi")
        case .Delete:
            dataApi = DeleteApi(bar: "DeleteApi")

        }

        self.title = "\(dataRows.description)"

        dataApi?.start(ignoreCache: cacheSwitch.on)
        dataApi?.responseJson({ [weak self] (json, error) -> Void in
            guard let strongSelf = self else { return }
            if (error != nil) {
                print("==========error: \(error)")
                strongSelf.bodyCell.textLabel?.text = error?.localizedDescription
            } else {
                strongSelf.headerCell.textLabel?.text = strongSelf.dataApi?.debugDescription
                strongSelf.bodyCell.textLabel?.text = "\(json.debugDescription)"
                print(strongSelf.dataApi.debugDescription)
                print("==========json: \(json)")
            }

            strongSelf.tableView.reloadData()
        })


        let one = GetApi(bar: "GetApi")
        let two = PostApi(bar: "PostApi")
        let three = GetApi(bar: "GetApi")
        let four = PostApi(bar: "PostApi")
        let five = GetApi(bar: "GetApi")
        let six = PostApi(bar: "PostApi")
        let batch = ETBatchRequest(requests: [one, two, three, four, five, six])
        batch.start()
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
