//
//  ProfileVC.swift
//  Streakz
//
//  Created by Michael on 3/17/21.
//

import UIKit
import GoogleSignIn
import FBSDKLoginKit
import Firebase

class ProfileVC: UIViewController {
    
    @IBOutlet weak var userInfoLabel: UILabel!
    
    let signOutSegue = "SignOutSegue"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setCurrentUser()
        
        // example: prints out documents stored in Firestore (Note: ASYNC!)
        /*
        db_firestore.collection("profiles_google").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    print("\(document.documentID) => \(document.data())")
                }
            }
        }
        db_firestore.collection("profiles_facebook").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    print("\(document.documentID) => \(document.data())")
                }
            }
        }
        db_firestore.collection("profiles_email").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    print("\(document.documentID) => \(document.data())")
                }
            }
        }
        */
    }
    
    func setCurrentUser() {
        if Auth.auth().currentUser != nil {
            // current user signed in through Facebook
            getEmailUserDatacompletion(completion: {(result)->Void in
                self.userInfoLabel.text = "EMAIL: " + result
            })
        } else if let googleUser = GIDSignIn.sharedInstance()?.currentUser {
            // current user signed in through Google
            self.userInfoLabel.text = "GOOGLE: " + googleUser.profile.email
            print("email:", googleUser.profile.email!)
            print("firstName:", googleUser.profile.givenName!)
            print("lastName:", googleUser.profile.familyName!)
            print("name:", googleUser.profile.name!)
            print("id:", googleUser.userID!)
            print("profilePictureURL:", googleUser.profile.imageURL(withDimension: UInt(round(100 * UIScreen.main.scale)))!)
        } else if AccessToken.current != nil {
            // current user signed in through Facebook
            getFacebookUserData(completion: {(result)->Void in
                self.userInfoLabel.text = "FACEBOOK: " + result
            })
        }
    }
    
    func getEmailUserDatacompletion(completion: @escaping (_ result:String) -> Void) {
        let docRef = db_firestore.collection("profiles_email").document((Auth.auth().currentUser?.email)!)
        docRef.getDocument {
            (document, error) in
            if let document = document,
                document.exists,
                let email: String = document.documentID as? String,
                let firstName: String = document["firstName"] as? String,
                let lastName: String = document["lastName"] as? String {
                print("email:", email)
                print("firstName:", firstName)
                print("lastName:", lastName)
                completion(document.documentID)
            } else {
                print("Document does not exist")
            }
        }
    }
    
    func getFacebookUserData(completion: @escaping (_ result:String) -> Void) {
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
                if let result = result as? Dictionary<String, AnyObject>,
                    let email: String = result["email"] as? String,
                    let firstName: String = result["first_name"] as? String,
                    let lastName: String = result["last_name"] as? String,
                    let name: String = result["name"] as? String,
                    let id: String = result["id"] as? String {
                    print("result:", result)
                    print("email:", email)
                    print("firstName:", firstName)
                    print("lastName:", lastName)
                    print("name:", name)
                    print("id:", id)
                    print("profilePictureURL: ", "https://graph.facebook.com/\(id)/picture?type=large")
                    completion(email)
                }
            }
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == signOutSegue {
            // sign out email user
            do { try Auth.auth().signOut() }
            catch { print("Email user already logged out") }
            
            // sign out Google user
            GIDSignIn.sharedInstance().signOut()
            
            // sign out Facebook user
            let loginManager = LoginManager()
            loginManager.logOut()
        }
    }

}
