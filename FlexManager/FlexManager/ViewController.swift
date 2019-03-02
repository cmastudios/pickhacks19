//
//  ViewController.swift
//  FlexManager
//
//  Created by Connor Monahan on 3/1/19.
//  Copyright © 2019 MEME TEME SUPREME. All rights reserved.
//

import UIKit
import Firebase

enum MeasurementType : String, CaseIterable {
    case arm = "Arm Angle"
}

class LoginController : UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    var handle: AuthStateDidChangeListenerHandle?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if user != nil && !user!.isAnonymous {
                self.performSegue(withIdentifier: "loggedInSegue", sender: self)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let h = handle {
            Auth.auth().removeStateDidChangeListener(h)
        }
    }
    
    @IBAction func login(_ sender: Any) {
        guard let email = usernameField.text else {
            return
        }
        guard let password = passwordField.text else {
            return
        }
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            guard let auth = result else {
                let alert = UIAlertController(title: "Failed to log in", message: error?.localizedDescription ?? "Unknown error", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            print("Logged in")
        }
    }
    
    @IBAction func signup(_ sender: Any) {
        guard let email = usernameField.text else {
            return
        }
        guard let password = passwordField.text else {
            return
        }
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            guard let auth = result else {
                let alert = UIAlertController(title: "Failed to create account", message: error?.localizedDescription ?? "Unknown error", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            print("Created")
        }
    }
    
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.tag == 0 {
            passwordField.becomeFirstResponder()
        } else if textField.tag == 1 {
            passwordField.resignFirstResponder()
        }
        return false
    }
}

class ViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }


}

class Exercise {
    var name: String
    var datetime: UInt64
    var completed: Bool
    
    init(fromParams name: String, datetime: UInt64, completed: Bool = false) {
        self.name = name
        self.datetime = datetime
        self.completed = completed
    }
}

class Exercises: UITableViewController {
    
    let elist : [Exercise] = [
        Exercise(fromParams: "Yeeting", datetime: 1551000000),
        Exercise(fromParams: "T-Posing", datetime: 1551502879, completed: true),
        Exercise(fromParams: "Dabbing", datetime: 1551502879),
    ]
    
    var exercisesToday : [Exercise] = []
    var exercisesPast : [Exercise] = []
    
    
    override func viewWillAppear(_ animated: Bool) {
        for e in elist {
            let date = Date(timeIntervalSince1970: TimeInterval(e.datetime))
            if abs(date.timeIntervalSinceNow) < 86400 {
                exercisesToday.append(e)
            } else {
                exercisesPast.append(e)
            }
        }
        
        super.viewWillAppear(animated)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return exercisesToday.count
        case 1:
            return exercisesPast.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Today's Exercises"
        case 1:
            return "Last Month"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : UITableViewCell!
        let e : Exercise?
        if indexPath.section == 0 {
            e = exercisesToday[indexPath.row]
            if e?.completed ?? true {
                cell = tableView.dequeueReusableCell(withIdentifier: "exerciseTodayComplete", for: indexPath)
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "exerciseTodayNotComplete", for: indexPath)
            }
        } else {
            e = exercisesPast[indexPath.row]
            cell = tableView.dequeueReusableCell(withIdentifier: "exerciseHistory", for: indexPath)
            
            if let date = e?.datetime {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .none
                
                let date = Date(timeIntervalSince1970: TimeInterval(date))
                
                // US English Locale (en_US)
                dateFormatter.locale = Locale(identifier: "en_US")
                let dstr = dateFormatter.string(from: date)
                cell.detailTextLabel?.text = dstr
            }
            
            

        }
        
        cell.textLabel?.text = e?.name ?? "Unknown"
        
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            let e = exercisesToday[indexPath.row]
            e.completed = true
            tableView.reloadData()
        }
    }
}


class MeasurementViewController : UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    var measurementType: MeasurementType? = .arm
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return MeasurementType.allCases.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return MeasurementType.allCases[row].rawValue
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        measurementType = MeasurementType.allCases[row]
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let tmmvc = segue.destination as? TakeMeasurementModalViewController {
            if let mt = measurementType {
                tmmvc.measurementType = mt
            } else {
                let alert = UIAlertController(title: "Error", message: "Please select a measurement type", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (uiaa) in
                    alert.dismiss(animated: true, completion: nil)
                }))
                self.present(alert, animated: true, completion: nil)
            }
        } else {
            print("ur bad")
        }
    }
    
    @IBAction func onLogout(_ sender: Any) {
        do {
            try Auth.auth().signOut()
        } catch let signoutError {
            print("your bad")
        }
        self.performSegue(withIdentifier: "unwindToLogin", sender: self)
    }
    
}

class TakeMeasurementModalViewController : UIViewController {
    var measurementType: MeasurementType!
    override func viewWillAppear(_ animated: Bool) {
        startTakingMeasurement()
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            stopTakingMeasurement()
            self.dismiss(animated: true, completion: nil)
        }
    }
}

func startTakingMeasurement() {
    let url = URL(string: "https://api.particle.io/v1/devices/pickhacks19-2/send")!
    var request = URLRequest(url: url)
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer 114a19795ef04a0b1ba4c856e8f8448a0cb9b139", forHTTPHeaderField: "Authorization")
    request.httpMethod = "POST"
    let parameters: [String: Any] = [:]
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
    } catch let error {
        print(error.localizedDescription)
    }
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data,
            let response = response as? HTTPURLResponse,
            error == nil else {                                              // check for fundamental networking error
                print("error", error ?? "Unknown error")
                return
        }
        
        guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
            print("statusCode should be 2xx, but is \(response.statusCode)")
            print("response = \(response)")
            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(responseString)")
            return
        }
        
        let responseString = String(data: data, encoding: .utf8)
        print("responseString = \(responseString)")
    }
    
    task.resume()
}

func stopTakingMeasurement() {
    let url = URL(string: "https://api.particle.io/v1/devices/pickhacks19-2/stop")!
    var request = URLRequest(url: url)
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer 114a19795ef04a0b1ba4c856e8f8448a0cb9b139", forHTTPHeaderField: "Authorization")
    request.httpMethod = "POST"
    let parameters: [String: Any] = [:]
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
    } catch let error {
        print(error.localizedDescription)
    }
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data,
            let response = response as? HTTPURLResponse,
            error == nil else {                                              // check for fundamental networking error
                print("error", error ?? "Unknown error")
                return
        }
        
        guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
            print("statusCode should be 2xx, but is \(response.statusCode)")
            print("response = \(response)")
            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(responseString)")
            return
        }
        
        let responseString = String(data: data, encoding: .utf8)
        print("responseString = \(responseString)")
    }
    
    task.resume()

}
