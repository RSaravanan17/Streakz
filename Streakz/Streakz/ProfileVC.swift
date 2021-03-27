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

// Extension of UIImageView class: function used to load a remote URL image
extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}

protocol ProfileDelegate {
    func updateProfile(firstName: String, lastName: String)
    func getProfile() -> Profile?
}

class ProfileVC: UIViewController, ProfileDelegate {
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userInfoLabel: UILabel!
    @IBOutlet weak var userFriendsLabel: UILabel!
    
    let signOutSegue = "SignOutSegue"
    let settingsSegue = "SettingsSegue"
    
    var userProfile: Profile?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setCurrentUser()
        
        // Round the profile image view
        userImageView.layer.borderWidth = 1.0
        userImageView.layer.masksToBounds = false
        userImageView.layer.borderColor = UIColor.white.cgColor
        userImageView.layer.cornerRadius = userImageView.frame.size.width / 2
        userImageView.clipsToBounds = true
        
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
        if let collection = cur_user_collection, let user = cur_user_email {
            db_firestore.collection(collection).document(user)
                .addSnapshotListener { documentSnapshot, error in
                    guard let document = documentSnapshot else {
                        print("Error fetching document: \(error!)")
                        return
                    }
                    do {
                        let userProfile = try document.data(as: Profile.self)
                        self.userProfile = userProfile
                        // Set profile picture image view
                        if let imageURL: String = userProfile?.profilePicture {
                            if imageURL == "" {
                                self.userImageView.image = UIImage(named: "ProfileImageBlank")
                            } else {
                                self.userImageView.load(url: URL(string: imageURL)!)
                            }
                        } else {
                            self.userImageView.image = UIImage(named: "ProfileImageBlank")
                        }
                        // Set first and last name labels
                        if let firstName: String = userProfile?.firstName,
                           let lastName: String = userProfile?.lastName {
                            self.userNameLabel.text = "\(firstName) \(lastName)"
                        }
                        // Set the number of friends label
                        if let friendsCount: Int = userProfile?.friends.count {
                            self.userFriendsLabel.text = "\(friendsCount)"
                        } else {
                            self.userFriendsLabel.text = "0"
                        }
                        if let email = cur_user_email {
                            self.userInfoLabel.text = "EMAIL: " + email
                        }
                    } catch let error {
                        print("Error deserializing data", error)
                    }
                }
        }
    }
    
    func updateProfile(firstName: String, lastName: String) {
        // Update profile in firebase
        if let owner = cur_user_email,
           let collection = cur_user_collection {
            let newData = ["firstName": firstName, "lastName": lastName]
            db_firestore.collection(collection).document(owner).setData(newData, merge: true)
        }
    }
    
    func getProfile() -> Profile? {
        return self.userProfile
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
        } else if segue.identifier == settingsSegue {
            if let destination = segue.destination as? SettingsVC {
                destination.profileDelegate = self as ProfileDelegate
            }
        }
    }

}
