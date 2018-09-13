//
//  ViewController.swift
//  LetsChat
//
//  Created by Zubair on 01/09/18.
//  Copyright © 2018 Avicenna. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import SVProgressHUD

class RegistrationViewController: UIViewController {
    
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var viewContainer: UIView!
    @IBOutlet weak var btnRegister: UIButton!
    @IBOutlet weak var txtUserName: UITextField!
    @IBOutlet weak var imgUserImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        viewContainer.layer.cornerRadius = 5
        viewContainer.layer.masksToBounds = true
        
        btnRegister.layer.cornerRadius = 5
        btnRegister.layer.masksToBounds = true
        
        //Add gesture on image
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        tapGesture.numberOfTapsRequired = 1
        imgUserImage.isUserInteractionEnabled = true
        imgUserImage.addGestureRecognizer(tapGesture)
    }
    
    @objc func imageTapped() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }

    func enableTextFields() {
        txtUserName.isUserInteractionEnabled = true
        txtEmail.isUserInteractionEnabled = true
        txtPassword.isUserInteractionEnabled = true
    }
    
    func disableTextFields() {
        txtUserName.isUserInteractionEnabled = false
        txtEmail.isUserInteractionEnabled = false
        txtPassword.isUserInteractionEnabled = false
    }

    //MARK: - Actions
    @IBAction func registerUser(_ sender: UIButton) {
        
        guard let userName = txtUserName.text, let email = txtEmail.text, let pwd = txtPassword.text else {
            print("Can't register.")
            return
        }
        
        //User Creation:
        
        disableTextFields()

        SVProgressHUD.show(withStatus: "Please wait...")
        SVProgressHUD.setDefaultMaskType(.black)
        
        Auth.auth().createUser(withEmail: email, password: pwd) { (user, error) in
            
            if error == nil {
                print("Registration Successfull")
                print("User details are \(user!)")
                
                guard let userId = user?.uid else {
                    print("User Id not available")
                    SVProgressHUD.dismiss()
                    self.enableTextFields()
                    return
                }
                
                //Image Uploading :
                let imageName = NSUUID().uuidString
                //Get storage reference to our profile_images DB
                let storageRef = Storage.storage().reference().child("profile_images").child("\(imageName).jpg")
                
                //Convert UIImage to Data
                
                //Compressed image using jpeg
                
                if let profileImage = self.imgUserImage.image, let imageData = UIImageJPEGRepresentation(profileImage, 0.1) {
                    
                    //if let imageData = UIImagePNGRepresentation(self.imgUserImage.image!) {
                    //Upload data on Firebase Storage
                    storageRef.putData(imageData, metadata: nil, completion: { (metaData, error) in
                        if error != nil {
                            print("Error while trying to upload image -> \(error!.localizedDescription)")
                            SVProgressHUD.dismiss()
                            self.enableTextFields()
                            return
                        }
                        
                        //Image uploaded successfully
                        print(metaData)
                        
                        //Register user
                        if let imageUrl = metaData?.downloadURL()?.absoluteString {
                            let dictUser = ["name":userName, "email":email,"profileImageUrl":imageUrl]
                            self.registerUser(withUid: userId, andJson: dictUser)
                            
                            SVProgressHUD.dismiss()
                            
                            self.enableTextFields()
                            
                            //Navigate to messages screen
                            self.navigateToMessagesScreen()
                        }
                        
                    })
                }
                
            }
            else {
                print(error!.localizedDescription)
                SVProgressHUD.dismiss()
                self.showAlert(withTitle: "Unable to register.", andMessage: error!.localizedDescription)
            }
        }
    }
    
    private func registerUser(withUid userId: String, andJson values: [String:String]) {
        //Storing user in Users with username and email
        //Get a reference to our users DB
        let usersDb = Database.database().reference().child("Users").child(userId)
        usersDb.setValue(values)
    }
    
    private func navigateToMessagesScreen() {
        //Navigate to messages view
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MessagesViewController") as! MessagesViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension RegistrationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        print(info)
        
        var selectedImage: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImage = editedImage
        }
        else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            selectedImage = originalImage
        }
        
        if let image = selectedImage {
            imgUserImage.image = image
        }
        
        
        dismiss(animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

