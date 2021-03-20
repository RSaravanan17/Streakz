//
//  LoginViewController.swift
//  Streakz
//
//  Created by Rithvik Saravanan on 3/20/21.
//

import UIKit
import Firebase

extension UITextField {
    func addBottomBorder(){
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(x: 0, y: self.frame.size.height - 1, width: UIScreen.main.bounds.size.width - 100, height: 1)
        bottomLine.backgroundColor = UIColor(named: "Streakz_DarkRed")?.cgColor
        borderStyle = .none
        layer.addSublayer(bottomLine)
    }
}

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var createAccountButton: UIButton!
    
    let signInSegue = "SignInSegue"
    let createAccountSegue = "CreateAccountSegue"
    let forgotPasswordSegue = "ForgotPasswordSegue"
    
    var loginSuccessful = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        do { try Auth.auth().signOut() }
        catch { print("already logged out") }
        
        Auth.auth().addStateDidChangeListener() {
          auth, user in
          
          if user != nil {
            self.performSegue(withIdentifier: self.signInSegue, sender: nil)
            self.emailTextField.text = nil
            self.passwordTextField.text = nil
          }
        }
        
        self.emailTextField.addBottomBorder()
        self.passwordTextField.addBottomBorder()
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == signInSegue {
            // if the login was successful, allow signInSegue to proceed
            return self.loginSuccessful
        } else {
            return true
        }
    }
    
    @IBAction func signInButtonPressed(_ sender: Any) {
        // verify if email and password are valid inputs
        guard let email = emailTextField.text,
              let password = passwordTextField.text,
              email.count > 0,
              password.count > 0
        else {
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) {
            user, error in
            if let error = error, user == nil {
                // show the login error as an alert
                let alert = UIAlertController(
                    title: "Sign in failed",
                    message: error.localizedDescription,
                    preferredStyle: .alert)
            
                alert.addAction(UIAlertAction(title:"OK", style:.default))
                self.present(alert, animated: true, completion: nil)
            } else {
                // no error occurred when logging in
                self.loginSuccessful = true
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
