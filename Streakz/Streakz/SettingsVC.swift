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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add red border to bottom of each name input text field
        self.addBottomBorder(view: firstNameTextView)
        self.addBottomBorder(view: lastNameTextView)
        
        // Set text field delegates to this VC to control keyboard dismiss functionality
        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        
        // Set the initial text of each naem field to the user's names
        let userProfile = self.profileDelegate.getProfile()
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
        
        // Check to see if the text fields are changed and not empty
        guard !firstNameTextField.text!.isEmpty,
              !lastNameTextField.text!.isEmpty
        else { return }
        guard !(firstNameTextField.text! == self.profileDelegate.getProfile()?.firstName &&
              lastNameTextField.text! == self.profileDelegate.getProfile()?.lastName)
        else { return }
        
        // Update the user's info with new names
        let firstName = firstNameTextField.text!
        let lastName = lastNameTextField.text!
        self.profileDelegate.updateProfile(firstName: firstName, lastName: lastName)
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
