//
//  BaseViewController.swift
//  LetsChat
//
//  Created by Zubair.Nagori on 13/09/18.
//  Copyright © 2018 Avicenna. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Add gesture to dismiss keyboard when user clicks outside of any textfield
        let dismissKeyboardGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        dismissKeyboardGesture.numberOfTapsRequired = 1
        view.addGestureRecognizer(dismissKeyboardGesture)

    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
