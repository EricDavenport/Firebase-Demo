//
//  ProfileViewController.swift
//  Firebase-Demo
//
//  Created by Eric Davenport on 3/2/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import UIKit
import FirebaseAuth

class ProfileViewController: UIViewController {
  
  @IBOutlet weak var profileImage: UIImageView!
  @IBOutlet weak var displayNameTextField: UITextField!
  @IBOutlet weak var emailLabel: UILabel!
  
  
  private lazy var imagePickerController: UIImagePickerController = {
    let ip = UIImagePickerController()
    ip.delegate = self
    return ip
  }()
  
  private var selectedImage: UIImage? {
    didSet {
      profileImage.image = selectedImage
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    displayNameTextField.delegate = self
    
    updateUI()
    
  }
  
  private func updateUI() {
    guard let user = Auth.auth().currentUser else {
      return
    }
    emailLabel.text = user.email
    displayNameTextField.text = user.displayName
    //    user.displayName
    //    user.email
    //    user.phoneNumber
    //    user.photoURL
    
  }
  
  
  @IBAction func updateProfileButtonPressed(_ sender: UIButton) {
    // change useers display name
    
    guard let displayName = displayNameTextField.text,
      !displayName.isEmpty else {
        print("missing fields")
        return
    }
    
    let request = Auth.auth().currentUser?.createProfileChangeRequest()
    
    request?.displayName = displayName
    
    request?.commitChanges(completion: { (error) in
      if let error = error {
        // TODO showAlert
        self.showAlert(title: "Profile Change", message: "Error showing profile: \(error)")
      } else {
        self.showAlert(title: "Profile Updated", message: "profile successulyy updated")
      }
    })
  }
  
  
  @IBAction func editProfilePhotoButtonPressed(_ sender: UIButton) {
    
    let alertController = UIAlertController(title: "Choose Photo Option", message: nil, preferredStyle: .actionSheet)
    
    let cameraAction = UIAlertAction(title: "Camera", style: .default) {
      alertAction in 
    }
    let photoLibraryAction = UIAlertAction(title: "Photo Library", style: .default) {
      alertAction in
      self.imagePickerController.sourceType = .photoLibrary
      self.present(self.imagePickerController, animated: true)
    }
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    if UIImagePickerController.isSourceTypeAvailable(.camera) {
      alertController.addAction(cameraAction)
    }
    alertController.addAction(photoLibraryAction)
    alertController.addAction(cancelAction)
    present(alertController, animated: true)
    
  }
  
}

extension ProfileViewController : UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
}

extension ProfileViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
      return
    }
    selectedImage = image
    dismiss(animated: true)
  }
}
