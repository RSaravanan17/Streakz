//
//  SettingsVC.swift
//  Streakz
//
//  Created by Michael on 3/26/21.
//

import UIKit

class SettingsVC: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var firstNameTextView: UIView!
    @IBOutlet weak var lastNameTextView: UIView!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var finalReminderToggle: UISwitch!
    @IBOutlet weak var finalReminderPicker: UIDatePicker!
    @IBOutlet weak var finalReminderPickerLabel: UILabel!
    
    var profileDelegate: ProfileDelegate! = nil
    var userProfile: Profile?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add red border to bottom of each name input text field
        self.addBottomBorder(view: firstNameTextView)
        self.addBottomBorder(view: lastNameTextView)
        
        // Set text field delegates to this VC to control keyboard dismiss functionality
        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        
        // Set the initial text of each naem field to the user's names
        userProfile = self.profileDelegate.getProfile()
        firstNameTextField.text = userProfile?.firstName
        lastNameTextField.text = userProfile?.lastName
        if let userReminderTime = userProfile?.finalReminderTime {
            finalReminderToggle.isOn = true
            finalReminderPicker.isEnabled = true
            finalReminderPickerLabel.isEnabled = true
            finalReminderPicker.date = userReminderTime
        } else {
            finalReminderToggle.isOn = false
            finalReminderPicker.isEnabled = false
            finalReminderPickerLabel.isEnabled = false
        }
    }
    
    @IBAction func finalReminderToggled(_ sender: Any) {
        if finalReminderToggle.isOn {
            finalReminderPickerLabel.isEnabled = true
            finalReminderPicker.isEnabled = true
        } else {
            finalReminderPickerLabel.isEnabled = false
            finalReminderPicker.isEnabled = false
        }
    }
    
    // Save user data upon screen dismissing
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let firstName = firstNameTextField.text, let lastName = lastNameTextField.text {
            if finalReminderToggle.isOn {
                userProfile?.finalReminderTime = finalReminderPicker.date
            } else {
                userProfile?.finalReminderTime = nil
            }
            userProfile?.firstName = firstName
            userProfile?.lastName = lastName
        } else {
            print("Failed to get text from text fields (should not happen because they're always set")
        }
        
        guard let email = cur_user_email,
              let collection = cur_user_collection
        else {
            return
        }
        do {
            try db_firestore.collection(collection).document(email).setData(from: userProfile)
        } catch let error {
            print("Error writing user profile settings to database in SettingsVC - \(error)")
        }
    }
    
    func addBottomBorder(view: UIView) {
        let bottomBorder = CALayer()
        bottomBorder.frame = CGRect(x:0, y: view.frame.height, width: view.frame.size.width-16, height:1)
        bottomBorder.backgroundColor = UIColor(named: "Streakz_DarkRed")?.cgColor
        view.layer.addSublayer(bottomBorder)
    }
    
    // Dismiss keyboards on touch outside of keyboard
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // Dismiss active keyboard on keyboard return pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
}
