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
    case data, download, upload, credit, batchChain
    
    var segueIdentifer: String {
        switch self {
        case .data:
            return "Data"
        case .download:
            return "Download"
        case .upload:
            return "Upload"
        case .credit:
            return "Auth"
        case .batchChain:
            return "BatchChain"
        }
    }
}

enum DataRows: Int {
    case get, post, put, delete
    
    var description: String {
        switch self {
        case .get:
            return "GET"
        case .post:
            return "POST"
        case .put:
            return "PUT"
        case .delete:
            return "DELETE"
        }
    }
}

enum DownloadRows: Int {
    case download, downloadWithResumeData

    var description: String {
        switch self {
        case .download:
            return "Download"
        case .downloadWithResumeData:
            return "DownloadWithResumeData"
        }
    }
}

enum UploadRows: Int {
    case uploadData, uploadFile, uploadStream

    var description: String {
        switch self {
        case .uploadData:
            return "UploadData"
        case .uploadFile:
            return "UploadFile"
            case .uploadStream:
            return "UploadStream"

        }
    }
}

enum AuthRows: Int {
    case httpBasic
    
    var description: String {
        switch self {
        case .httpBasic:
            return "HttpBasic"
        }
    }
}

enum BatchChainRows: Int {
    case batch, chain
    var description: String {
        switch self {
        case .batch:
            return "Batch"
        case .chain:
            return "Chain"
        }
    }
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
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = Sections(rawValue: indexPath.section)!
        performSegue(withIdentifier: section.segueIdentifer, sender: indexPath)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        let dest = segue.destination
         let indexPath = sender as! IndexPath
        if let dest = dest as? DataTableViewController {
            dest.dataRows = DataRows(rawValue: indexPath.row)
        } else if let dest = dest as? DownloadTableViewController {
            dest.downloadRows = DownloadRows(rawValue: indexPath.row)
        } else if let dest = dest as? UploadTableViewController {
            dest.uploadRows = UploadRows(rawValue: indexPath.row)
        } else if let dest = dest as? AuthTableViewController {
            dest.authRows = AuthRows(rawValue: indexPath.row)
        }  else if let dest = dest as? BatchChainTableViewController {
            dest.bcRows = BatchChainRows(rawValue: indexPath.row)
        }
    }

}
