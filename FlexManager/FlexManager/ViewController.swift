//
//  ViewController.swift
//  FlexManager
//
//  Created by Connor Monahan on 3/1/19.
//  Copyright © 2019 MEME TEME SUPREME. All rights reserved.
//

import UIKit

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
}

