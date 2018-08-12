//
//  ListViewController.swift
//  ShoppingList
//
//  Created by Mohamed Sobhi  Fouda on 6/25/18.
//  Copyright © 2018 Mohamed Sobhi Fouda. All rights reserved.
//

import UIKit
import CloudKit
import SVProgressHUD
import Flurry_iOS_SDK

class ListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AddItemViewControllerDelegate  {
    
    // MARK: Add Item View Controller Delegate Methods
    func controller(controller: AddItemViewController, didAddItem item: CKRecord) {
        // Add Item to Items
        items.append(item)
        
        // Sort Items
        sortItems()
        
        // Update Table View
        tableView.reloadData()
        
        // Update View
        updateView()
    }
    
    func controller(controller: AddItemViewController, didUpdateItem item: CKRecord) {
        // Sort Items
        sortItems()
        
        // Update Table View
        tableView.reloadData()
    }
    
    
    let RecordTypeLists = "Lists"
    let RecordTypeItems = "Items"
    static let ItemCell = "ItemCell"
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    var list: CKRecord!
    var items = [CKRecord]()
    
    var selection: Int?
    // MARK: View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set Title
        title = list.object(forKey: "name") as? String
        
        setupView()
        fetchItems()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: View Methods
    private func setupView() {
        tableView.isHidden = true
        messageLabel.isHidden = true
        activityIndicatorView.startAnimating()
    }
    
    private func updateView() {
        let hasRecords = items.count > 0
        
        tableView.isHidden = !hasRecords
        messageLabel.isHidden = hasRecords
        activityIndicatorView.stopAnimating()
    }
    
    // MARK: Helper Methods
    private func fetchItems() {
        // Fetch Private Database
        let privateDatabase = CKContainer.default().privateCloudDatabase
        
        // Initialize Query
        let reference = CKReference(recordID: list.recordID, action: .deleteSelf)
        let query = CKQuery(recordType: RecordTypeItems, predicate: NSPredicate(format: "list == %@", reference))
        
        // Configure Query
        query.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        // Perform Query
        privateDatabase.perform(query, inZoneWith: nil) { (records, error) -> Void in
           DispatchQueue.main.sync { () -> Void in
                // Process Response on Main Thread
            self.processResponseForQuery(records: records, error: error as NSError?)
            }
        }
    }
    
    private func processResponseForQuery(records: [CKRecord]?, error: NSError?) {
        var message = ""
        
        if let error = error {
            print(error)
            message = "Error Fetching Items for List"
            
        } else if let records = records {
            items = records
            
            if items.count == 0 {
                message = "No Items Found"
            }
            
        } else {
            message = "No Items Found"
        }
        
        if message.isEmpty {
            tableView.reloadData()
        } else {
            messageLabel.text = message
        }
        
        updateView()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: Table View Data Source Methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1;
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Dequeue Reusable Cell
        let cell = tableView.dequeueReusableCell(withIdentifier: ListViewController.ItemCell, for: indexPath as IndexPath)
        
        // Configure Cell
        cell.accessoryType = .detailDisclosureButton
        
        // Fetch Record
        let item = items[indexPath.row]
        
        if let itemName = item.object(forKey: "name") as? String {
            // Configure Cell
            cell.textLabel?.text = itemName
            
        } else {
            cell.textLabel?.text = "-"
        }
        
        if let itemNumber = item.object(forKey: "number") as? Int {
            // Configure Cell
            cell.detailTextLabel?.text = "\(itemNumber)"
            
        } else {
            cell.detailTextLabel?.text = "1"
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        guard editingStyle == .delete else { return }
        
        // Fetch Record
        let item = items[indexPath.row]
        
        // Delete Record
        deleteRecord(item: item)
    }
    
    private func deleteRecord(item: CKRecord) {
        // Fetch Private Database
        let privateDatabase = CKContainer.default().privateCloudDatabase
        
        // Show Progress HUD
        SVProgressHUD.show()
        
        // Delete List
        privateDatabase.delete(withRecordID: item.recordID) { (recordID, error) -> Void in
            DispatchQueue.main.sync { () -> Void in
                // Dismiss Progress HUD
                SVProgressHUD.dismiss()
                
                // Process Response
                self.processResponseForDeleteRequest(record: item, recordID: recordID, error: error as? NSError)
            }
        }
    }
    
    private func processResponseForDeleteRequest(record: CKRecord, recordID: CKRecordID?, error: NSError?) {
        var message = ""
        
        if let error = error {
            print(error)
            message = "We are unable to delete the item."
            
        } else if recordID == nil {
            message = "We are unable to delete the item."
        }
        
        if message.isEmpty {
            // Calculate Row Index
            let index = items.index(of: record)
            
            if let index = index {
                // Update Data Source
                items.remove(at: index)
                
                if items.count > 0 {
                    // Update Table View
                    tableView.deleteRows(at: [NSIndexPath(row: index, section: 0) as IndexPath], with: .right)
                    
                } else {
                    // Update Message Label
                    messageLabel.text = "No Items Found"
                    
                    // Update View
                    updateView()
                }
            }
            
        } else {
            // Initialize Alert Controller
            let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            
            // Present Alert Controller
            present(alertController, animated: true, completion: nil)
        }
    }
    
    private func sortItems() {
        self.items.sort {
            var result = false
            let name0 = $0.object(forKey: "name") as? String
            let name1 = $1.object(forKey: "name") as? String
            
            if let itemName0 = name0, let itemName1 = name1 {
                result = itemName0.localizedCaseInsensitiveCompare(itemName1) == .orderedAscending
            }
            
            return result
        }
    }

    // MARK: Segue Life Cycle
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "ItemDetail" {
            // Fetch Destination View Controller
            let addItemViewController = segue.destination as! AddItemViewController
            
            // Configure View Controller
            addItemViewController.list = list
            addItemViewController.delegate = self
            
            if let selection = selection {
                // Fetch Item
                let item = items[selection]
                
                // Configure View Controller
                addItemViewController.item = item
            }
        }
    }
    
 
    // MARK: Table View Delegate Methods
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        
        // Save Selection
        selection = indexPath.row
        
        // Perform Segue
        performSegue(withIdentifier: "ItemDetail", sender: self)
    }
    
    // Deleteing
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        
        // Fetch Record
        let item = items[indexPath.row]
        
        // Delete Record
        deleteRecord(item: item)
    }
    
}
