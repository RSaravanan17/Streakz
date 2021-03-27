//
//  SignUpViewController.swift
//  Streakz
//
//  Created by Rithvik Saravanan on 3/20/21.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift

class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var termsAndConditionsSwitch: UISwitch!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var signInButton: UIButton!
    
    let signUpSegue = "SignUpSegue"
    let returnLoginSegue1 = "ReturnLoginSegue1"
    
    var signInSuccessful = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.firstNameTextField.addBottomBorderForNameFields()
        self.lastNameTextField.addBottomBorderForNameFields()
        self.emailTextField.addBottomBorder()
        self.passwordTextField.addBottomBorder()
        self.confirmPasswordTextField.addBottomBorder()
        
        self.firstNameTextField.delegate = self
        self.lastNameTextField.delegate = self
        self.emailTextField.delegate = self
        self.passwordTextField.delegate = self
        self.confirmPasswordTextField.delegate = self
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == signUpSegue {
            // if the login was successful, allow signUpSegue to proceed
            return self.signInSuccessful
        } else {
            return true
        }
    }
    
    @IBAction func createAccountButtonPressed(_ sender: Any) {
        // verify if inputs are valid
        guard let firstName = firstNameTextField.text,
              let lastName = lastNameTextField.text,
              let email = emailTextField.text,
              let password = passwordTextField.text,
              let confirmPassword = confirmPasswordTextField.text,
              firstName.count > 0,
              lastName.count > 0,
              email.count > 0,
              password.count > 0,
              confirmPassword.count > 0
        else {
            return
        }
        
        if (!self.termsAndConditionsSwitch.isOn) {
            // present an alert if terms and conditions have not been accepted
            let alert = UIAlertController(
                title: "Sign up failed",
                message: "Terms and conditions must be accepted",
                preferredStyle: .alert)
          
            alert.addAction(UIAlertAction(title:"OK", style:.default))
            self.present(alert, animated: true, completion: nil)
        } else if (password != confirmPassword) {
            // present an alert if password does not match confirmPassword
            let alert = UIAlertController(
                title: "Sign up failed",
                message: "Password must match Confirm Password",
                preferredStyle: .alert)
          
            alert.addAction(UIAlertAction(title:"OK", style:.default))
            self.present(alert, animated: true, completion: nil)
        } else {
            Auth.auth().createUser(withEmail: email, password: password) {
                user, error in
                if let error = error, user == nil {
                    // show the login error as an alert
                    let alert = UIAlertController(
                        title: "Sign up failed",
                        message: error.localizedDescription,
                        preferredStyle: .alert)
                  
                    alert.addAction(UIAlertAction(title:"OK", style:.default))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    // no error occurred when logging in
                    // directly sign in the newly created user
                    Auth.auth().signIn(withEmail: email,
                                       password: password)
                    // create the user a profile and push it to firebase
                    let newProfile = Profile(firstName: firstName, lastName: lastName)
                    do {
                        try db_firestore.collection("profiles_email").document(email).setData(from: newProfile, merge: true)
                    } catch let error {
                        print("Error adding new user to database", error)
                    }
                    self.signInSuccessful = true
                    self.performSegue(withIdentifier: self.signUpSegue, sender: nil)
                }
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // Handler for return key pressed on text fields
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let nextTag = textField.tag + 1
        
        if let nextResponder = textField.superview?.viewWithTag(nextTag) {
            // Shift focus from text field to the next text field upon return key pressed
            nextResponder.becomeFirstResponder()
        } else {
            // Dismiss keyboard of the last text input once its return key is pressed
            textField.resignFirstResponder()
        }

        return true
    }
}
