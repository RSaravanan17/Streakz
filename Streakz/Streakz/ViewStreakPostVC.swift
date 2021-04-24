//
//  ViewStreakPostVC.swift
//  Streakz
//
//  Created by John Cauvin on 4/24/21.
//

import UIKit

class ViewStreakPostVC: UIViewController {
    
    @IBOutlet weak var posterName: UILabel!
    @IBOutlet weak var postDate: UILabel!
    @IBOutlet weak var streakName: UILabel!
    @IBOutlet weak var postDescription: UILabel!
    @IBOutlet weak var postImage: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var posterNameStr: String? = nil
    var streakPost: StreakPost? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if let name = posterNameStr {
            // other person's streak post, show their name
            posterName.text = name
        } else if let profile = cur_user_profile {
            posterName.text = profile.firstName + " " + profile.lastName
        } else {
            let alert = UIAlertController(
                title: "Invalid Session",
                message: "We're having trouble finding out who you are, please try signing out and signing back in",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
        
        if let post = streakPost {
            postDate.text = post.datePosted.shortDate
            streakName.text = post.streak.name
            postDescription.text = post.postText
            if post.image.isEmpty {
                postImage.image = UIImage(named: "StreakzLogo")
            } else {
                postImage.load(url: URL(string: post.image)!)
            }
        }
    }
}
