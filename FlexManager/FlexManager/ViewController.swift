//
//  ViewController.swift
//  FlexManager
//
//  Created by Connor Monahan on 3/1/19.
//  Copyright © 2019 MEME TEME SUPREME. All rights reserved.
//

import UIKit
import Firebase
import PromiseKit

enum MeasurementType : String, CaseIterable {
    case arm = "Arm Angle"
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
    var baseline: Bool
    
    init(fromParams name: String, datetime: UInt64, baseline: Bool = false, completed: Bool = false) {
        self.name = name
        self.datetime = datetime
        self.completed = completed
        self.baseline = baseline
    }
}

class Exercises: UITableViewController {
    
    var exercisesToday : [Exercise] = []
    var exercisesPast : [Exercise] = []
    
    func loadExercises() {
        refreshControl?.beginRefreshing()
        exercisesToday = []
        exercisesPast = []
        guard let myUserId = Auth.auth().currentUser?.uid else {
            return
        }
        Database.database().reference().child("users").child(myUserId).child("exercises")
            .observeSingleEvent(of: .value) { (snapshot) in
                for exercise in snapshot.children.allObjects as! [DataSnapshot] {
                    let name = exercise.key
                    for schedule in exercise.childSnapshot(forPath: "history").children.allObjects as! [DataSnapshot] {
                        let time = UInt64(schedule.key) ?? 0
                        let completed = schedule.childSnapshot(forPath: "complete").value as? Bool == true
                        let baseline = schedule.childSnapshot(forPath: "baseline").value as? Bool == true
                        let e = Exercise(fromParams: name, datetime: time, baseline: baseline, completed: completed)
                        let date = Date(timeIntervalSince1970: TimeInterval(e.datetime))
                        if abs(date.timeIntervalSinceNow) < 86400 {
                            self.exercisesToday.append(e)
                        } else {
                            self.exercisesPast.append(e)
                        }
                    }
                }
                self.tableView.reloadData()
                self.refreshControl?.endRefreshing()
        }
    }
    
    @IBAction func onRefresh(_ sender: Any) {
        loadExercises()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadExercises()
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
            } else if e?.baseline ?? false {
                cell = tableView.dequeueReusableCell(withIdentifier: "exerciseTodayBaseline", for: indexPath)
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
        
//        if indexPath.section == 0 {
//            let e = exercisesToday[indexPath.row]
//            e.completed = true
//            tableView.reloadData()
//        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let tmmvc = segue.destination as? TakeMeasurementModalViewController {
            guard let i = tableView.indexPathForSelectedRow?.row else {return}
            let e = exercisesToday[i]
            tmmvc.exercise = e
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
                tmmvc.exercise = Exercise(fromParams: mt.rawValue, datetime: 0)
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
        } catch _ {
            print("your bad")
        }
        self.performSegue(withIdentifier: "unwindToLogin", sender: self)
    }
    
}

class TakeMeasurementModalViewController : UIViewController {
    var exercise: Exercise?
    
    override func viewWillAppear(_ animated: Bool) {
        let delay: Double
        if exercise?.baseline == false {
            delay = 30
        } else {
            delay = 10
        }
        var devid: String = ""
        
        firstly {
            readUserDeviceId()
        }.then { (did: String) -> Promise<DatabaseReference> in
            devid = did
            return clearMeasurementField(devid: devid)
        }.then { ref in
            startTakingMeasurement(devid: devid)
        }.then { rslt in
            after(seconds: TimeInterval(delay))
        }.then { rslt in
            stopTakingMeasurement(devid: devid)
        }.ensure {
            self.dismiss(animated: true, completion: nil)
        }.catch { e in
            print(e)
        }
        
        
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
//            stopTakingMeasurement()
//            self.dismiss(animated: true, completion: nil)
//        }
    }
    
    func cleanup() {
        
    }
}

enum DataReadError: Error {
    case httperror(Int)
    case invalidchars
    case nodevid
    case nouserid
}

func readUserDeviceId() -> Promise<String> {
    return Promise { promise in
        if let myUserId = Auth.auth().currentUser?.uid {
            Database.database().reference().child("users").child(myUserId).child("device")
                .observeSingleEvent(of: .value) { (snapshot) in
                    if let devid = snapshot.value as? String {
                        promise.fulfill(devid)
                    } else {
                        promise.reject(DataReadError.nodevid)
                    }
            }
        } else {
            promise.reject(DataReadError.nouserid)
        }
    }
}

func clearMeasurementField(devid: String) -> Promise<DatabaseReference> {
    return Promise { promise in
        Database.database().reference().child("devices").child(devid).child("measurements").removeValue { (error, ref) in
            promise.resolve(error, ref)
        }
    }
}

func startTakingMeasurement(devid: String) -> Promise<String> {
    guard let did = devid.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
        return Promise.init(error: DataReadError.invalidchars)
    }
    let url = URL(string: "https://api.particle.io/v1/devices/" + did + "/send")!
    var request = URLRequest(url: url)
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer 114a19795ef04a0b1ba4c856e8f8448a0cb9b139", forHTTPHeaderField: "Authorization")
    request.httpMethod = "POST"
    let parameters: [String: Any] = [:]
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
    } catch let error {
        return Promise.init(error: error)
    }
    
    return Promise { promise in
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                let response = response as? HTTPURLResponse,
                error == nil else {                                              // check for fundamental networking error
                    promise.reject(error!)
                    return
            }
            
            guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                let responseString = String(data: data, encoding: .utf8)
                print("responseString = \(String(describing: responseString))")
                promise.reject(DataReadError.httperror(response.statusCode))
                return
            }
            
            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(String(describing: responseString))")
            promise.fulfill(responseString ?? "")
        }
        
        task.resume()
    }
}

func stopTakingMeasurement(devid: String) -> Promise<String> {
    guard let did = devid.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
        return Promise.init(error: DataReadError.invalidchars)
    }
    let url = URL(string: "https://api.particle.io/v1/devices/" + did + "/stop")!
    var request = URLRequest(url: url)
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer 114a19795ef04a0b1ba4c856e8f8448a0cb9b139", forHTTPHeaderField: "Authorization")
    request.httpMethod = "POST"
    let parameters: [String: Any] = [:]
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
    } catch let error {
        return Promise.init(error: error)
    }
    
    return Promise { promise in
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                let response = response as? HTTPURLResponse,
                error == nil else {                                              // check for fundamental networking error
                    promise.reject(error!)
                    return
            }
            
            guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                let responseString = String(data: data, encoding: .utf8)
                print("responseString = \(String(describing: responseString))")
                promise.reject(DataReadError.httperror(response.statusCode))
                return
            }
            
            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(String(describing: responseString))")
            promise.fulfill(responseString ?? "")
        }
        
        task.resume()
    }
}
