//
//  SignUpViewController.swift
//  Streakz
//
//  Created by Rithvik Saravanan on 3/20/21.
//

import UIKit
import Firebase

class SignUpViewController: UIViewController {
    
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
                    db_firestore.collection("profiles_email").document(email).setData([
                        "firstName": firstName,
                        "lastName": lastName
                    ], merge: true) {
                        err in
                        if let err = err {
                            print("Error writing document: \(err)")
                        } else {
                            print("Document successfully written!")
                        }
                    }
                    self.signInSuccessful = true
                    self.performSegue(withIdentifier: self.signUpSegue, sender: nil)
                }
            }
        }
    }

}
