//
//  CompleteStreakVC.swift
//  Streakz
//
//  Created by Zac Bonar on 3/23/21.
//

import UIKit
import FirebaseStorage

class CompleteStreakVC: UIViewController, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var streakTitleLabel: UILabel!
    @IBOutlet weak var currentDateLabel: UILabel!
    @IBOutlet weak var oldStreakNumberLabel: UILabel!
    @IBOutlet weak var newStreakNumberLabel: UILabel!
    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    
    let commentPlaceholder = "Comment on your latest streak achievement"
    let textFieldGray = UIColor.gray.withAlphaComponent(0.5)
    
    var streakSub: StreakSubscription!
    var curUserProfile: Profile? = nil
    var uploadedImage: UIImage? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        commentTextView.delegate = self
        commentTextView.text = commentPlaceholder
        commentTextView.textColor = textFieldGray

        // make description text view match name text field
        commentTextView.layer.cornerRadius = 5
        commentTextView.layer.borderColor = textFieldGray.cgColor
        commentTextView.layer.borderWidth = 0.5
        commentTextView.clipsToBounds = true
        
        streakTitleLabel.text = streakSub.name
        currentDateLabel.text = Date().fullDate
        oldStreakNumberLabel.text = String(streakSub.streakNumber)
        newStreakNumberLabel.text = String(streakSub.streakNumber + 1)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        imageView.isHidden = true
    }
    
    @IBAction func uploadImagePressed(_ sender: Any) {
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerController.SourceType.photoLibrary
        image.allowsEditing = true
        self.present(image, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        self.dismiss(animated: true, completion: nil)
        guard let image = info[.editedImage] as? UIImage else { return }
        self.uploadedImage = image
        imageView.image = image
        imageView.isHidden = false
    }
    
    @IBAction func postStreakPressed(_ sender: Any) {
        _ = streakSub.completeStreak()
        var postText = commentTextView.text ?? ""
        if postText.isEmpty || postText == commentPlaceholder {
            postText = "Streak completed on \(Date().shortDate)!"
        }
        
        guard let collection = cur_user_collection, let email = cur_user_email else {
            print("Error fetching user collection and email after post streak button pressed in CompleteStreakVC")
            return
        }
        
        if let image = uploadedImage {
            // user uploaded an image
            // file the image in cloud storage under user's streakposts with a randomly generated string
            let streakPostFile = collection + "/" + email + "/StreakPosts/" + UUID().uuidString + ".png"
            let storageRef = storage.reference().child(streakPostFile)
            storageRef.putData(image.pngData()!, metadata: nil) { (metadata, error) in
                storageRef.downloadURL { (url, error) in
                    var imageLink = ""
                    if let downloadURL = url {
                        imageLink = downloadURL.absoluteString
                    }
                    self.uploadStreakPost(postText: postText, imageLink: imageLink)
                }
            }
        } else {
            // user didn't upload an image, leave URL blank and upload post
            self.uploadStreakPost(postText: postText, imageLink: "")
        }
        
        navigationController?.popViewController(animated: true)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if commentTextView.textColor == textFieldGray {
            commentTextView.text = nil
            commentTextView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if commentTextView.text.isEmpty {
            commentTextView.text = commentPlaceholder
            commentTextView.textColor = textFieldGray
        }
    }

    func uploadStreakPost(postText: String, imageLink: String) {
        let streakPost = StreakPost(for: streakSub, postText: postText, image: imageLink)
        
        if let curProfile = curUserProfile {
            // update Firebase
            curProfile.streakPosts.append(streakPost)
            do {
                try db_firestore.collection(cur_user_collection!).document(cur_user_email!).setData(from: curProfile)
            } catch let error {
                print("Error writing profile to Firestore after streak post update: \(error)")
            }
        }
    }
}
