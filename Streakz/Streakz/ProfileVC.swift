//
//  ProfileVC.swift
//  Streakz
//
//  Created by Michael on 3/17/21.
//

import UIKit
import GoogleSignIn
import FBSDKLoginKit

class ProfileVC: UIViewController {
    
    let signOutSegue = "SignOutSegue"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == signOutSegue {
            // sign out Google user
            GIDSignIn.sharedInstance().signOut()
            
            // sign out Facebook user
            let loginManager = LoginManager()
            loginManager.logOut()
        }
    }

}
