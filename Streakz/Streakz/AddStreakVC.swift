//
//  AddStreakVC.swift
//  Streakz
//
//  Created by John Cauvin on 3/21/21.
//

import UIKit

class AddStreakVC: UIViewController, UITextViewDelegate {
    
    // outlets
    @IBOutlet weak var descTextView: UITextView!
    
    let descPlaceholder = "Do push ups three times a week for the gains"
    let textFieldGray = UIColor.gray.withAlphaComponent(0.5)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        descTextView.delegate = self
        descTextView.text = descPlaceholder
        descTextView.textColor = textFieldGray

        // make description text view match name text field
        descTextView.layer.cornerRadius = 5
        descTextView.layer.borderColor = textFieldGray.cgColor
        descTextView.layer.borderWidth = 0.5
        descTextView.clipsToBounds = true
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    func textViewDidBeginEditing(_ textView: UITextView) {
        if descTextView.textColor == textFieldGray {
            descTextView.text = nil
            descTextView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if descTextView.text.isEmpty {
            descTextView.text = descPlaceholder
            descTextView.textColor = textFieldGray
        }
    }
}
