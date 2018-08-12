//
//  AddListViewController.swift
//  ShoppingList
//
//  Created by Mohamed Sobhi  Fouda on 6/24/18.
//  Copyright © 2018 Mohamed Sobhi Fouda. All rights reserved.
//

import UIKit
import CloudKit
import SVProgressHUD
import Flurry_iOS_SDK

protocol AddListViewControllerDelegate {
    func controller(controller: AddListViewController, didAddList list: CKRecord)
    func controller(controller: AddListViewController, didUpdateList list: CKRecord)
}

class AddListViewController: UIViewController {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var delegate: AddListViewControllerDelegate?
    var newList: Bool = true
    
    var list: CKRecord?
    
    @IBAction func cancel(sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func save(sender: AnyObject) {
    
        // Helpers
        let name = self.nameTextField.text! as NSString
        
        // Fetch Private Database
        let privateDatabase = CKContainer.default().privateCloudDatabase
        
        if list == nil {
            list = CKRecord(recordType: "Lists")
        }
        
        // Configure Record
        list?.setObject(name, forKey: "name")
        
        // Show Progress HUD
        SVProgressHUD.show()
        
        // Save Record
        privateDatabase.save(list!) { (record, error) -> Void in
            DispatchQueue.main.sync {
                // Dismiss Progress HUD
                SVProgressHUD.dismiss()
                
                // Process Response
                self.processResponse(record: record, error: error)
            }
            
        }
        
        let parameters = ["List" : nameTextField.text]
        Flurry.logEvent("Added-List", withParameters: parameters)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
        
        // Update Helper
        self.newList = self.list == nil
        
        // Add Observer
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(AddListViewController.textFieldTextDidChange(notification:)), name: NSNotification.Name.UITextFieldTextDidChange, object: nameTextField)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nameTextField.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func setupView() {
        updateNameTextField()
        updateSaveButton()
    }
    
    // MARK: -
    private func updateNameTextField() {
        if let name = list?.object(forKey: "name") as? String {
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
    
    // MARK: -
    // MARK: Helper Methods
    private func processResponse(record: CKRecord?, error: Error?) {
        var message = ""
        
        if let error = error {
            print(error)
            message = "We were not able to save your list."
            
        } else if record == nil {
            message = "We were not able to save your list."
        }
        
        if !message.isEmpty {
            // Initialize Alert Controller
            let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            
            // Present Alert Controller
            present(alertController, animated: true, completion: nil)
            
        } else {
            // Notify Delegate
            if newList {
                delegate?.controller(controller: self, didAddList: list!)
            } else {
                delegate?.controller(controller: self, didUpdateList: list!)
            }
            
            // Pop View Controller
            self.dismiss(animated: true, completion: nil)
            
        }
    }
    
    // MARK: -
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

}
