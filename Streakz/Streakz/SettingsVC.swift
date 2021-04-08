//
//  SettingsVC.swift
//  Streakz
//
//  Created by Michael on 3/26/21.
//

import UIKit

class SettingsVC: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var firstNameTextView: UIView!
    @IBOutlet weak var lastNameTextView: UIView!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var finalReminderToggle: UISwitch!
    @IBOutlet weak var finalReminderPicker: UIDatePicker!
    @IBOutlet weak var finalReminderPickerLabel: UILabel!
    @IBOutlet weak var profilePicView: UIImageView!
    
    var profileDelegate: ProfileDelegate! = nil
    var userProfile: Profile?
    var newProfilePic: UIImage? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // round profile picture
        profilePicView.layer.borderWidth = 1.0
        profilePicView.layer.masksToBounds = false
        profilePicView.layer.borderColor = UIColor(named: "Streakz_Inverse")?.cgColor
        profilePicView.layer.cornerRadius = profilePicView.frame.size.width / 2
        profilePicView.clipsToBounds = true
        profilePicView.image = UIImage(named: "ProfileImageBlank")
        
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
        if let profilePicStr = userProfile?.profilePicture, !profilePicStr.isEmpty, let url = URL(string: profilePicStr) {
            profilePicView.load(url: url)
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
    
    @IBAction func profilePictureClicked(_ sender: Any) {
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerController.SourceType.photoLibrary
        image.allowsEditing = true
        self.present(image, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        self.dismiss(animated: true, completion: nil)
        guard let image = info[.editedImage] as? UIImage else { return }
        // store new photo
        self.newProfilePic = image
        // update profile picture for user to see
        profilePicView.image = image
    }
    
    // Save user data upon screen dismissing
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        guard let firstName = firstNameTextField.text, let lastName = lastNameTextField.text else {
            print("Failed to get text from text fields (should not happen because they're always set")
            return
        }
        guard let email = cur_user_email, let collection = cur_user_collection else {
            print("Failed capture cur user email and collection globals")
            return
        }

        if finalReminderToggle.isOn {
            userProfile?.finalReminderTime = finalReminderPicker.date
        } else {
            userProfile?.finalReminderTime = nil
        }
        
        userProfile?.firstName = firstName
        userProfile?.lastName = lastName
        
        if let newPic = newProfilePic {
            // user uploaded new profile picture, need to store it and create download link before writing update to firebase
            let profilePicFile = collection + "/" + email + "/ProfilePictures/" + UUID().uuidString + ".jpeg"
            let storageRef = storage.reference().child(profilePicFile)
            storageRef.putData(newPic.jpegData(compressionQuality: 0.5)!, metadata: nil) { (metadata, error) in
                storageRef.downloadURL { (url, error) in
                    if let downloadURL = url {
                        self.userProfile?.profilePicture = downloadURL.absoluteString
                    }
                    self.uploadProfile(collection: collection, email: email)
                }
            }
        } else {
            // no new photo, upload updated profile as usual
            self.uploadProfile(collection: collection, email: email)
        }
    }
    
    func uploadProfile(collection: String, email: String) {
        do {
            try db_firestore.collection(collection).document(email).setData(from: userProfile)
        } catch let error {
            print("Error writing user profile settings to database in SettingsVC - \(error)")
        }
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
