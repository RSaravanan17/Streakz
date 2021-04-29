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
import FirebaseStorage

let db_firestore = Firestore.firestore()
let storage = Storage.storage()
var cur_user_email: String? = nil
var cur_user_collection: String? = nil
var cur_user_profile: Profile? = nil
var cur_user_profile_listener: ListenerRegistration?  = nil

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

class LoginViewController: UIViewController, UITextFieldDelegate, GIDSignInDelegate, LoginButtonDelegate {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var googleSignInButton: GIDSignInButton!
    @IBOutlet weak var facebookLoginButton: FBLoginButton!
    @IBOutlet weak var createAccountButton: UIButton!
    
    let signInSegue = "SignInSegue"
    let createAccountSegue = "CreateAccountSegue"
    let forgotPasswordSegue = "ForgotPasswordSegue"
    
    var loginSuccessful = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("DEBUG: loginVC loaded")

        // sign out user
        //signOutEmailUser()
        //signOutGoogleUser()
        //signOutFacebookUser()
        
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
        
        self.emailTextField.delegate = self
        self.passwordTextField.delegate = self
        
        // Google sign-in
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance().delegate = self
        
        // Adjust styling on google button
        self.googleSignInButton.style = .wide
        
        // Facebook sign-in
        self.facebookLoginButton.delegate = self
        self.facebookLoginButton.permissions = ["public_profile", "email"]
        
        // Style Facebook sign in button to match styling of Google sign in button
        for const in self.facebookLoginButton.constraints {
            if const.firstAttribute == NSLayoutConstraint.Attribute.height && const.constant == 28 {
                self.facebookLoginButton.removeConstraint(const)
            }
        }
        self.facebookLoginButton.translatesAutoresizingMaskIntoConstraints = false
        self.facebookLoginButton.leadingAnchor.constraint(equalTo: googleSignInButton.leadingAnchor).isActive = true
        self.facebookLoginButton.trailingAnchor.constraint(equalTo: googleSignInButton.trailingAnchor).isActive = true
    }
    
    func signOutFacebookUser() {
        let loginManager = LoginManager()
        loginManager.logOut()
    }
    
    func signOutEmailUser() {
        do { try Auth.auth().signOut() }
        catch { print("Email user already logged out") }
    }
    
    func signOutGoogleUser() {
        GIDSignIn.sharedInstance().signOut()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("DEBUG: loginVC appeared")

        // automatically sign in the user with Google
        GIDSignIn.sharedInstance()?.restorePreviousSignIn()
        
        // automatically sign in the user with Facebook
        if let token = AccessToken.current, !token.isExpired {
            setFBLoginEmailAndType(completion: {(result) -> Void in
                cur_user_email = result
                cur_user_collection = "profiles_facebook"
                
                self.loginSuccessful = true
                self.performSegue(withIdentifier: self.signInSegue, sender: nil)
            })
        }
    }
    
    func setFBLoginEmailAndType(completion: @escaping (String?) -> Void) {
        let accessToken = AccessToken.current!
        let graphRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                      parameters: ["fields": "email"],
                                                      tokenString: accessToken.tokenString,
                                                      version: nil,
                                                      httpMethod: .get)
        graphRequest.start { (connection, result, error) -> Void in
            if error == nil, let result = result as? Dictionary<String, AnyObject> {
                completion(result["email"] as? String)
            }
            else if let error = error {
                print("Error when fetching facebook profile information: \(error)")
            } else {
                print("Error fetching facebook profile")
            }
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
            self.loginSuccessful = true
            db_firestore.collection("profiles_google").document(user.profile.email).getDocument {
                (document, error) in
                if let document = document, document.exists {
                    print("User exists, no need to make new profile")
                } else {
                    print("New google user. Creating new profile")
                    let userProfile = Profile(firstName: user.profile.givenName!, lastName: user.profile.familyName!)                    // TODO: get user profile picture
                    do {
                        try db_firestore.collection("profiles_google").document(user.profile.email).setData(from: userProfile, merge: true)
                    } catch let error {
                        print("Error adding new user to database", error)
                    }
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
                                                          parameters: ["fields": "email, first_name, last_name"],
                                                          tokenString: accessToken.tokenString,
                                                          version: nil,
                                                          httpMethod: .get)
            graphRequest.start { (connection, result, error) -> Void in
                if let error = error {
                    print("error: \(error)")
                } else {
                    if let result = result as? [String:String],
                        let email: String = result["email"],
                        let firstName: String = result["first_name"],
                        let lastName: String = result["last_name"] {
                        
                        cur_user_email = email
                        cur_user_collection = "profiles_facebook"
                        
                        db_firestore.collection("profiles_facebook").document(email).getDocument {
                            (document, error) in
                            if let document = document, document.exists {
                                print("Facebook User exists, no need to make new profile")
                                self.loginSuccessful = true
                            } else {
                                print("New facebook user. Creating new profile")
                                let userProfile = Profile(firstName: firstName, lastName: lastName)
                                // TODO: get user profile picture
                                do {
                                    try db_firestore.collection("profiles_facebook").document(email).setData(from: userProfile, merge: true)
                                    self.loginSuccessful = true
                                } catch let error {
                                    print("Error adding new user to database", error)
                                    self.loginSuccessful = false
                                }
                            }
                            
                            if self.shouldPerformSegue(withIdentifier: self.signInSegue, sender: self) {
                                self.performSegue(withIdentifier: self.signInSegue, sender: nil)
                            }
                        }
                    }
                }
            }
            
            
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        print("logged out")
        return
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == signInSegue {
            return self.loginSuccessful
        } else {
            return true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        setCurUserEmailAndType()
        print("DEBUG: I'm gonna call setCurUserProfile")
        setCurUserProfile()
    }
    
    @IBAction func signInButtonPressed(_ sender: Any) {
        self.signInWithEmailPassword()
    }
    
    func signInWithEmailPassword() {
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

    // globally stores current user's login type and email for email and Google sign-in
    // Facebook sign-in is taken care of in before perfoming the segue because it requires an async callback function
    func setCurUserEmailAndType() {
        if Auth.auth().currentUser != nil {
            // current user signed in through email
            cur_user_email = Auth.auth().currentUser!.email
            cur_user_collection = "profiles_email"
        } else if let googleUser = GIDSignIn.sharedInstance()?.currentUser {
            // current user signed in through Google
            cur_user_email = googleUser.profile.email
            cur_user_collection = "profiles_google"
        }
    }
    
    func setCurUserProfile() {
        
        if let listener = cur_user_profile_listener {
            print("DEBUG: THIS IS BAD, you can't call setCurUserProfile before releasing the old listener. I guess I'll do it for you")
            listener.remove()
            cur_user_profile_listener = nil
        }
        
        
        if let collection = cur_user_collection, let document = cur_user_email {
            print("DEBUG: creating listener for \(document) in \(collection)")
            cur_user_profile_listener = db_firestore.collection(collection).document(document)
                .addSnapshotListener { documentSnapshot, error in
                    print("DEBUG: cur_user_profile snapshot listener triggered")
                    guard let document = documentSnapshot else {
                        print("cur_user_profile error fetching document: \(error!)")
                        return
                    }
                    guard document.data() != nil else {
                        print("cur_user_profile fetch - document data was empty.")
                        
                        return
                    }
                    do {
                        cur_user_profile = try document.data(as: Profile.self)
                        print("DEBUG: cur_user_profile successfully set to \(cur_user_profile!.firstName)")
                        self.setupNotifications(profile: cur_user_profile!)
                        print("notifications reset")
                    } catch let error {
                        print("Error deserializing data", error)
                    }
                }
        }
    }
    
    func setupNotifications(profile: Profile) {
        let notifCenter = UNUserNotificationCenter.current()
        // remove existing notifications in case any settings changed
        notifCenter.removeAllPendingNotificationRequests()
        
        var needFinalReminder = false
        for streak in profile.subscribedStreaks {
            if streak.canBeCompletedToday() {
                needFinalReminder = true
                let request = newStreakNotification(streak: streak)
                notifCenter.add(request)
            }
        }
        
        // add final reminder notification if there are outstanding streaks and the user wants final reminders
        if let finalReminderTime = profile.finalReminderTime, needFinalReminder {
            let request = newFinalReminderNotification(finalReminderTime: finalReminderTime)
            notifCenter.add(request)
        }
    }
    
    func newStreakNotification(streak: StreakSubscription) -> UNNotificationRequest {
        let calendar = Calendar.current
        let content = UNMutableNotificationContent()
        content.title = "Streak reminder"
        content.body = "Remember to complete your \(streak.name) streak"
        
        var reminderTime = DateComponents()
        reminderTime.hour = calendar.component(.hour, from: streak.reminderTime)
        reminderTime.minute = calendar.component(.minute, from: streak.reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: reminderTime, repeats: false)
        
        return UNNotificationRequest(identifier: streak.name, content: content, trigger: trigger)
    }
    
    func newFinalReminderNotification(finalReminderTime: Date) -> UNNotificationRequest {
        let calendar = Calendar.current
        let content = UNMutableNotificationContent()
        content.title = "Last call!"
        content.body = "Final reminder to complete any outstanding streaks for the day"
        
        var reminderTime = DateComponents()
        reminderTime.hour = calendar.component(.hour, from: finalReminderTime)
        reminderTime.minute = calendar.component(.minute, from: finalReminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: reminderTime, repeats: false)
        
        return UNNotificationRequest(identifier: "final reminder", content: content, trigger: trigger)
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
            // Sign user in once password input return key is pressed
            self.signInWithEmailPassword()
        }

        return true
    }
}
