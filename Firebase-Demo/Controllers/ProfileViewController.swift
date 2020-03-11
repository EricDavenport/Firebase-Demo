//
//  ProfileViewController.swift
//  Firebase-Demo
//
//  Created by Eric Davenport on 3/2/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import UIKit
import FirebaseAuth
import Kingfisher

class ProfileViewController: UIViewController {
  
  @IBOutlet weak var profileImageView: UIImageView!
  @IBOutlet weak var displayNameTextField: UITextField!
  @IBOutlet weak var emailLabel: UILabel!
  
  
  private lazy var imagePickerController: UIImagePickerController = {
    let ip = UIImagePickerController()
    ip.delegate = self
    return ip
  }()
  
  private var selectedImage: UIImage? {
    didSet {
      profileImageView.image = selectedImage
    }
  }
  
  private var databaseService = DatabaseService()
  private let storageService = StorageService()
  
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
    profileImageView.kf.setImage(with: user.photoURL)
    //    user.displayName
    //    user.email
    //    user.phoneNumber
    //    user.photoURL
    
  }
  
  
  @IBAction func updateProfileButtonPressed(_ sender: UIButton) {
    // change useers display name
    
    guard let displayName = displayNameTextField.text,
      !displayName.isEmpty,
      let selectedImage = selectedImage else {
        print("missing fields")
        return
    }
    
    guard let user = Auth.auth().currentUser else { return }
    
    // resize image before uploading to FireBase
    let resizedImage = UIImage.resizeImage(originalImage: selectedImage, rect: profileImageView.bounds)
    
    print("oroginal image size: \(selectedImage.size)")
    print("resized image size: \(resizedImage.size)")
    
    // TODO: call ZrageService.upload
    storageService.uploadPhoto(userId: user.uid, image: resizedImage) { (result) in
      // code here to add photoURL to the users PhotoURL property then commit changes
      switch result {
      case .failure(let error):
        DispatchQueue.main.async {
          self.showAlert(title: "Error uploading photo", message: "\(error.localizedDescription)")
        }
      case .success(let url):
        
        self.updateDatabaseUser(displayName: displayName, photoURL: url.absoluteString)
        
        // refactor into its own function
        let request = Auth.auth().currentUser?.createProfileChangeRequest()
        request?.displayName = displayName
        request?.photoURL = url
        request?.commitChanges(completion: { [unowned self](error) in
          if let error = error {
            DispatchQueue.main.async {
              self.showAlert(title: "Error updating profile", message: "Error changing profile: \(error.localizedDescription).")
            }
          } else {
            DispatchQueue.main.async {
              self.showAlert(title: "Profile Updated", message: "Profile successfully updated")
            }
          }
        })
      }
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
  
  private func updateDatabaseUser(displayName: String, photoURL: String) {
    databaseService.updateDatabaseUser(displayName: displayName, photoURL: photoURL) {  (result) in
      switch result {
      case .failure(let error):
        print("failed to update db user: \(error.localizedDescription)")
      case .success:
        print("successfully updated db user")
      }
    }
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
  
  
  @IBAction func signOutButtonPressed(_ sender: UIButton) {
    do {
      try Auth.auth().signOut()
      UIViewController.showViewController(storyboardName: "LoginView", viewControllerId: "LoginViewController")
    } catch {
      DispatchQueue.main.async {
        self.showAlert(title: "Error signing out", message: "\(error.localizedDescription).")
      }
    }
    
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
