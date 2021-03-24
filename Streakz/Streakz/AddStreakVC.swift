//
//  AddStreakVC.swift
//  Streakz
//
//  Created by John Cauvin on 3/21/21.
//

import UIKit

class AddStreakVC: UIViewController, UITextViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    // outlets
    @IBOutlet weak var descTextView: UITextView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var addStreakButton: UIButton!
    @IBOutlet weak var viewSunday: UIView!
    @IBOutlet weak var viewMonday: UIView!
    @IBOutlet weak var viewTuesday: UIView!
    @IBOutlet weak var viewWednesday: UIView!
    @IBOutlet weak var viewThursday: UIView!
    @IBOutlet weak var viewFriday: UIView!
    @IBOutlet weak var viewSaturday: UIView!
    
    @IBOutlet weak var reminderTimePicker: UIDatePicker!
    @IBOutlet weak var visibilityPicker: UIPickerView!
    
    var daysOfWeekViews: [UIView?] = []
    var daysOfWeekButtons: [UIButton] = []
    let daysOfWeekTitles = ["Su", "M", "Tu", "W", "Th", "F", "Sa"]
    var daysOfWeekSelected = [false, false, false, false, false, false, false]
    
    let descPlaceholder = "Do push ups three times a week for the gains"
    let textFieldGray = UIColor.gray.withAlphaComponent(0.5)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        visibilityPicker.dataSource = self
        visibilityPicker.delegate = self
        
        descTextView.delegate = self
        descTextView.text = descPlaceholder
        descTextView.textColor = textFieldGray

        // make description text view match name text field
        descTextView.layer.cornerRadius = 5
        descTextView.layer.borderColor = textFieldGray.cgColor
        descTextView.layer.borderWidth = 0.5
        descTextView.clipsToBounds = true
        
        // make add streak button rounded and colored
        addStreakButton.backgroundColor = UIColor.init(named: "Streakz_DarkRed")
        addStreakButton.layer.cornerRadius = 25
        addStreakButton.tintColor = UIColor.black
        
        daysOfWeekViews = [
            viewSunday,
            viewMonday,
            viewTuesday,
            viewWednesday,
            viewThursday,
            viewFriday,
            viewSaturday
        ]
        
        // Testing for button
        for (i, view) in daysOfWeekViews.enumerated() {
            let button = UIButton(type: .custom)
            button.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
            button.backgroundColor = UIColor.gray
            button.layer.cornerRadius = 0.5 * button.bounds.size.width
            button.clipsToBounds = true
            button.setTitle(daysOfWeekTitles[i], for: .normal)
            button.setTitleColor(UIColor.black, for: .normal)
            button.addTarget(self, action: #selector(dayPressed), for: .touchUpInside)
            daysOfWeekButtons.append(button)
            view?.addSubview(button)
        }
    }
    
    @objc func dayPressed(sender: UIButton!) {
        let index = daysOfWeekTitles.firstIndex(of: sender.title(for: .normal)!)!
        daysOfWeekSelected[index] = !daysOfWeekSelected[index]
        if daysOfWeekSelected[index] {
            daysOfWeekButtons[index].backgroundColor = UIColor.init(named: "Streakz_DarkRed")
        } else {
            daysOfWeekButtons[index].backgroundColor = UIColor.gray
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return 3
        } else {
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            return "Only Me"
        } else if component == 1 {
            return "Friends"
        } else {
            return "Anyone"
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
