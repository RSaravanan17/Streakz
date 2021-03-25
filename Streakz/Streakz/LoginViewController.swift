//
//  LoginViewController.swift
//  Streakz
//
//  Created by Rithvik Saravanan on 3/20/21.
//

import UIKit
import Firebase
import GoogleSignIn
import FBSDKLoginKit
import FirebaseFirestore
import FirebaseFirestoreSwift
import Combine

let db_firestore = Firestore.firestore()
var cur_user_email: String? = nil
var cur_user_collection: String? = nil
var cur_user_profile: Profile? = nil

// UI styling for text fields
extension UITextField {
    func addBottomBorder(){
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(x: 0, y: self.frame.size.height - 1, width: UIScreen.main.bounds.size.width - 100, height: 1)
        bottomLine.backgroundColor = UIColor(named: "Streakz_DarkRed")?.cgColor
        borderStyle = .none
        layer.addSublayer(bottomLine)
    }
    func addBottomBorderForNameFields() {
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(x: 0, y: self.frame.size.height - 1, width: (UIScreen.main.bounds.size.width - 110) / 2, height: 1)
        bottomLine.backgroundColor = UIColor(named: "Streakz_DarkRed")?.cgColor
        borderStyle = .none
        layer.addSublayer(bottomLine)
    }
}

class LoginViewController: UIViewController, GIDSignInDelegate, LoginButtonDelegate {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var facebookLoginButton: FBLoginButton!
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
            self.loginSuccessful = true
            self.performSegue(withIdentifier: self.signInSegue, sender: nil)
            self.emailTextField.text = nil
            self.passwordTextField.text = nil
          }
        }
        
        // update UI for aesthetics
        self.emailTextField.addBottomBorder()
        self.passwordTextField.addBottomBorder()
        
        // Google sign in
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance().delegate = self
        
        // Facebook sign in
        self.facebookLoginButton.delegate = self
        self.facebookLoginButton.permissions = ["public_profile", "email"]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // automatically sign in the user with Google
        GIDSignIn.sharedInstance()?.restorePreviousSignIn()
        
        // automatically sign in the user with Facebook
        if let token = AccessToken.current,
            !token.isExpired {
            loginSuccessful = true
            self.performSegue(withIdentifier: self.signInSegue, sender: nil)
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            if (error as NSError).code == GIDSignInErrorCode.hasNoAuthInKeychain.rawValue {
                print("The user has not signed in before or they have since signed out.")
            } else {
                print("\(error.localizedDescription)")
            }
            return
        } else {
            loginSuccessful = true
            // TODO push actual profile object instead
//            let newUser = Profile(firstName: user.profile.givenName!, lastName: user.profile.familyName!)
            db_firestore.collection("profiles_google").document(user.profile.email).setData([
                "firstName": user.profile.givenName!,
                "lastName": user.profile.familyName!
            ], merge: true) {
                err in
                if let err = err {
                    print("Error writing document: \(err)")
                } else {
                    print("Document successfully written!")
                }
            }
            self.performSegue(withIdentifier: self.signInSegue, sender: nil)
        }
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        if let error = error {
            // process error
            print("\(error.localizedDescription)")
        } else if let result = result,
                  result.isCancelled {
            // handle cancellations
            print("result:", result)
        } else {
            // navigate to other view
            guard let accessToken = FBSDKLoginKit.AccessToken.current else { return }
            let graphRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                          parameters: ["fields": "id, email, name, first_name, last_name, picture.type(large)"],
                                                          tokenString: accessToken.tokenString,
                                                          version: nil,
                                                          httpMethod: .get)
            graphRequest.start { (connection, result, error) -> Void in
                if let error = error {
                    print("error: \(error)")
                } else {
                    if let result = result as? [String:String],
                        let fbId: String = result["id"],
                        let email: String = result["email"],
                        let name: String = result["name"],
                        let firstName: String = result["first_name"],
                        let lastName: String = result["last_name"],
                        let imageURL = ((result["picture"] as? [String: Any])?["data"] as? [String: Any])?["url"] as? String {
                        db_firestore.collection("profiles_facebook").document(email).setData([
                            "id": fbId,
                            "email": email,
                            "name": name,
                            "firstName": firstName,
                            "lastName": lastName,
                            "profilePicture": imageURL
                        ], merge: true) {
                            err in
                            if let err = err {
                                print("Error writing document: \(err)")
                            } else {
                                print("Document successfully written!")
                            }
                        }
                    }
                }
            }
            
            loginSuccessful = true
            self.performSegue(withIdentifier: self.signInSegue, sender: nil)
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        print("logged out")
        return
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == signInSegue {
            // if the login was successful, allow signInSegue to proceed
            return self.loginSuccessful
        } else {
            return true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        setCurUserEmailAndType()
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

    func setCurUserEmailAndType() {
        if Auth.auth().currentUser != nil {
            // current user signed in through Facebook
            cur_user_email = Auth.auth().currentUser!.email
            cur_user_collection = "profiles_email"
        } else if let googleUser = GIDSignIn.sharedInstance()?.currentUser {
            // current user signed in through Google
            cur_user_email = googleUser.profile.email
            cur_user_collection = "profiles_google"
        } else if AccessToken.current != nil {
            // current user signed in through Facebook
            let accessToken = AccessToken.current!
            let graphRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                          parameters: ["fields": "email"],
                                                          tokenString: accessToken.tokenString,
                                                          version: nil,
                                                          httpMethod: .get)
            graphRequest.start { (connection, result, error) -> Void in
                if error == nil, let result = result as? Dictionary<String, AnyObject> {
                    cur_user_email = result["email"] as? String
                    cur_user_collection = "profiles_facebook"
                }
                else if let error = error {
                    print("Error when fetching facebook profile information: \(error)")
                } else {
                    print("Error fetching facebook profile")
                }
            }
        }
    }
    
    func setCurUserProfile() {
        if let collection = cur_user_collection, let document = cur_user_email {
            db_firestore.collection(collection).document(document).getDocument {
                (document, error) in
                let result = Result {
                    try document?.data(as: Profile.self)
                }
                switch result {
                case .success(let fetchedProfile):
                    if let fetchedProfile = fetchedProfile {
                        print("Received profile successfully")
                        cur_user_profile = fetchedProfile
                        print(fetchedProfile.firstName, fetchedProfile.lastName, fetchedProfile.friends[0].firstName)
                    } else {
                        print("Document doesn't exist")
                    }
                case .failure(let error):
                    print("Error decoding document into profile: \(error)")
                }
            }
        } else {
            print("Error fetching current profile - user email and/or profile_type is nil")
        }
    }
}
