//
//  ForgotPasswordViewController.swift
//  Streakz
//
//  Created by Rithvik Saravanan on 3/20/21.
//

import UIKit
import Firebase

class ForgotPasswordViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    
    let resetPasswordSignInSegue = "ResetPasswordSignInSegue"
    let returnLoginSegue2 = "ReturnLoginSegue2"
    
    var passwordResetEmailSuccessful = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.emailTextField.addBottomBorder()
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == resetPasswordSignInSegue {
            // if the password reset email was sent successfully, allow resetPasswordSignInSegue to proceed
            return self.passwordResetEmailSuccessful
        } else {
            return true
        }
    }
    
    @IBAction func signInButtonPressed(_ sender: Any) {
        // verify if input is valid
        guard let email = emailTextField.text,
              email.count > 0
        else {
            return
        }
        
        Auth.auth().sendPasswordReset(withEmail: email) {
            error in
            if let error = error {
                // show the password reset error as an alert
                let alert = UIAlertController(
                    title: "Sign in failed",
                    message: error.localizedDescription,
                    preferredStyle: .alert)
            
                alert.addAction(UIAlertAction(title:"OK", style:.default))
                self.present(alert, animated: true, completion: nil)
            } else {
                // no error occurred when sending password reset email
                // show the password reset error as an alert
                let alert = UIAlertController(
                    title: "Reset Password Email Sent",
                    message: "Reset your password with the link in your email",
                    preferredStyle: .alert)
            
                alert.addAction(UIAlertAction(title:"OK", style:.default, handler: {
                    _ in
                    // allow the segue to happen if password reset email was sent successfully
                    self.passwordResetEmailSuccessful = true
                    self.performSegue(withIdentifier: self.resetPasswordSignInSegue, sender: nil)
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}
