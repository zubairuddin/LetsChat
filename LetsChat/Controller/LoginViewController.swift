//
//  LoginViewController.swift
//  LetsChat
//
//  Created by Zubair on 02/09/18.
//  Copyright © 2018 Avicenna. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

class LoginViewController: BaseViewController {

    //MARK: - Outlets
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var viewContainer: UIView!
    @IBOutlet weak var btnLogin: UIButton!
    @IBOutlet weak var btnRegister: UIButton!
    
    //MARK: - View Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        setUpView()
        
        //Check if user logged-in
        if Auth.auth().currentUser != nil {
            navigateToMessagesScreen()
        }

    }
    
    //MARK: - Local methods
    private func navigateToMessagesScreen() {
        //Navigate to messages view
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MessagesViewController") as! MessagesViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func setUpView() {
        viewContainer.layer.cornerRadius = 5
        viewContainer.layer.masksToBounds = true
        
        btnLogin.layer.cornerRadius = 5
        btnLogin.layer.masksToBounds = true
        
        btnRegister.layer.cornerRadius = 5
        btnRegister.layer.masksToBounds = true

    }

    //MARK: - Actions
    @IBAction func registerAction(_ sender: UIButton) {
        
        //Change back button title, this needs to be done before pushing
        let backItem = UIBarButtonItem()
        backItem.title = ""
        self.navigationItem.backBarButtonItem = backItem // This will show in the next view controller being pushed

        let vc = storyboard?.instantiateViewController(withIdentifier: "RegistrationViewController") as! RegistrationViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func loginAction(_ sender: UIButton) {
        
        SVProgressHUD.show(withStatus: "Please wait...")
        SVProgressHUD.setDefaultMaskType(.black)
        
        Auth.auth().signIn(withEmail: txtEmail.text!, password: txtPassword.text!) { (user, error) in
            
            SVProgressHUD.dismiss()
            
            if error == nil {
                self.navigateToMessagesScreen()
            }
            else {
                print("Error while logging-in \(error!.localizedDescription)")
                self.showAlert(withTitle: "Unable to login.", andMessage: error!.localizedDescription)
            }
        }
    }
    
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == txtEmail {
            txtPassword.becomeFirstResponder()
        }
        else {
            textField.resignFirstResponder()
        }
        return true
    }
}
