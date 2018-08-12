//
//  AddItemViewController.swift
//  ShoppingList
//
//  Created by Mohamed Sobhi  Fouda on 6/25/18.
//  Copyright © 2018 Mohamed Sobhi Fouda. All rights reserved.
//

import UIKit
import CloudKit
import SVProgressHUD
import Flurry_iOS_SDK

protocol AddItemViewControllerDelegate {
    func controller(controller: AddItemViewController, didAddItem item: CKRecord)
    func controller(controller: AddItemViewController, didUpdateItem item: CKRecord)
}

class AddItemViewController: UIViewController {
    
    let RecordTypeLists = "Lists"
    let RecordTypeItems = "Items"
    
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var numberStepper: UIStepper!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var delegate: AddItemViewControllerDelegate?
    var newItem: Bool = true
    
    var list: CKRecord!
    var item: CKRecord?
    
    // MARK: Actions
    @IBAction func numberDidChange(sender: UIStepper) {
        let number = Int(sender.value)
        
        // Update Number Label
        numberLabel.text = "\(number)"
    }
    
    @IBAction func cancel(sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func save(sender: AnyObject) {

        // Helpers
        let name = nameTextField.text
        let number = Int(numberStepper.value)
        
        // Fetch Private Database
        let privateDatabase = CKContainer.default().privateCloudDatabase
        
        if item == nil {
            // Create Record
            item = CKRecord(recordType: RecordTypeItems)
            
            // Initialize Reference
            let listReference = CKReference(recordID: list.recordID, action: .deleteSelf)
            
            // Configure Record
            item?.setObject(listReference, forKey: "list")
        }
        
        // Configure Record
        item?.setObject(name as! CKRecordValue, forKey: "name")
        item?.setObject(number as CKRecordValue, forKey: "number")
        
        // Show Progress HUD
        SVProgressHUD.show()
        
        print(item?.recordType)
        
        // Save Record
        privateDatabase.save(item!) { (record, error) -> Void in
            DispatchQueue.main.sync { () -> Void in
                // Dismiss Progress HUD
                SVProgressHUD.dismiss()
                
                // Process Response
                self.processResponse(record: record, error: error as? NSError)
            }
        }
        
        let parameters = ["Item" : nameTextField.text]
        Flurry.logEvent("Added-Item", withParameters: parameters)
    }
    
    
    // MARK: View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        
        // Update Helper
        newItem = item == nil
        
        // Add Observer
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(AddItemViewController.textFieldTextDidChange(notification:)), name: NSNotification.Name.UITextFieldTextDidChange, object: nameTextField)
    }
    
    private func updateNumberStepper() {
        if let number = item?.object(forKey: "number") as? Double {
            numberStepper.value = number
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        nameTextField.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Notification Handling
    @objc func textFieldTextDidChange(notification: NSNotification) {
        updateSaveButton()
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: View Methods
    private func setupView() {
        updateNameTextField()
        updateNumberStepper()
        updateSaveButton()
    }
    
    // MARK: -
    private func updateNameTextField() {
        if let name = item?.object(forKey: "name") as? String {
            nameTextField.text = name
        }
    }
    
    // MARK: -
    private func updateSaveButton() {
        let text = nameTextField.text
        
        if let name = text {
            saveButton.isEnabled = !name.isEmpty
        } else {
            saveButton.isEnabled = false
        }
    }
    
    // MARK: Helper Methods
    private func processResponse(record: CKRecord?, error: NSError?) {
        var message = ""
        
        if let error = error {
            print(error)
            message = "We were not able to save your item."
            
        } else if record == nil {
            message = "We were not able to save your item."
        }
        
        if !message.isEmpty {
            // Initialize Alert Controller
            let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            
            // Present Alert Controller
            present(alertController, animated: true, completion: nil)
            
        } else {
            // Notify Delegate
            if newItem {
                delegate?.controller(controller: self, didAddItem: item!)
            } else {
                delegate?.controller(controller:  self, didUpdateItem: item!)
            }
            
            // Pop View Controller
            self.dismiss(animated: true, completion: nil)
            
        }
    }


}
