//
//  SignUpViewController.swift
//  Streakz
//
//  Created by Rithvik Saravanan on 3/20/21.
//

import UIKit
import Firebase

class SignUpViewController: UIViewController {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var termsAndConditionsSwitch: UISwitch!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var signInButton: UIButton!
    
    let signUpSegue = "SignUpSegue"
    let returnLoginSegue1 = "ReturnLoginSegue1"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func createAccountButtonPressed(_ sender: Any) {
        // verify if inputs are valid
        guard let name = nameTextField.text,
              let email = emailTextField.text,
              let password = passwordTextField.text,
              let confirmPassword = confirmPasswordTextField.text,
              name.count > 0,
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
                    self.performSegue(withIdentifier: self.signUpSegue, sender: nil)
                }
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}