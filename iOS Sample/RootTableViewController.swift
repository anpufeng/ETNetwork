//
//  RootTableViewController.swift
//  iOS Sample
//
//  Created by ethan on 15/11/27.
//  Copyright © 2015年 ethan. All rights reserved.
//

import UIKit
import ETNetwork

enum Sections: Int {
    case Data, Download, Upload, Credit
    
    var segueIdentifer: String {
        switch self {
        case .Data:
            return "Data"
        case .Download:
            return "Download"
        case .Upload:
            return "Upload"
        case .Credit:
            return "Credit"
        }
    }
}

enum DataRows: Int {
    case Get, Post, Put, Delete
    
    
}

enum DownloadRows: Int {
    case Download, DownloadWithResumeData
}

enum UploadRows: Int {
    case UploadData, UploadFile, UploadStream
}

enum AuthRows: Int {
    case HttpBasic
}


class RootTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

   //MARK: - Table view delegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let section = Sections(rawValue: indexPath.section)!
        self.performSegueWithIdentifier(section.segueIdentifer, sender: indexPath)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        let dest = segue.destinationViewController
        if let dest = dest as? DataTableViewController {
            let indexPath = sender as! NSIndexPath
            dest.dataRows = DataRows(rawValue: indexPath.row)
        }
    }

}
