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

class RegistrationViewController: BaseViewController {
    
    //MARK: - Outlets
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var viewContainer: UIView!
    @IBOutlet weak var btnRegister: UIButton!
    @IBOutlet weak var txtUserName: UITextField!
    @IBOutlet weak var imgUserImage: UIImageView!
    
    //MARK: - View Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        setUpView()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        enableTextFields()
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
                let imageName = NSUUID().uuidString //to make image name unique
                
                //Get storage reference to our profile_images DB
                let storageRef = Storage.storage().reference().child("profile_images").child("\(imageName).jpg")
                
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
    
    @IBAction func selectImageAction(_ sender: UIButton) {
        
        let alert = UIAlertController(title: "Select Profile Image", message: nil, preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { (action) in
            self.openCamera()
        }
        let galleryAction = UIAlertAction(title: "Photo Library", style: .default) { (action) in
            self.openPhotoLibrary()
        }

        alert.addAction(cameraAction)
        alert.addAction(galleryAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    //MARK: - Other Methods
    private func openCamera() {
        //Instantiate UIImagePickerController
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            //Show UIImagePicker with Camera
            picker.sourceType = .camera
            present(picker, animated: true, completion: nil)
        }
        else {
            //Show Alert
            let alert  = UIAlertController(title: "Warning", message: "Camera not available", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func openPhotoLibrary() {
        //Instantiate UIImagePickerController
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }

    private func setUpView() {
        viewContainer.layer.cornerRadius = 5
        viewContainer.layer.masksToBounds = true
        
        btnRegister.layer.cornerRadius = 5
        btnRegister.layer.masksToBounds = true
        
        imgUserImage.layer.cornerRadius = imgUserImage.frame.size.width / 2
        imgUserImage.layer.borderWidth = 5
        imgUserImage.layer.borderColor = UIColor.white.cgColor
        imgUserImage.layer.masksToBounds = true
    }

    private func enableTextFields() {
        txtUserName.isUserInteractionEnabled = true
        txtEmail.isUserInteractionEnabled = true
        txtPassword.isUserInteractionEnabled = true
    }
    
    private func disableTextFields() {
        txtUserName.isUserInteractionEnabled = false
        txtEmail.isUserInteractionEnabled = false
        txtPassword.isUserInteractionEnabled = false
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

//MARK: - UIImagePickerController delegate
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

