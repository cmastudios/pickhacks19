//
//  Login.swift
//  FlexManager
//
//  Created by Connor Monahan on 3/2/19.
//  Copyright © 2019 MEME TEME SUPREME. All rights reserved.
//

import Foundation
import UIKit
import Firebase

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
            guard result != nil else {
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
            guard result != nil else {
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

