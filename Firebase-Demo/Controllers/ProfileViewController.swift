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

enum ViewState {
  case myItems
  case favorites
}

class ProfileViewController: UIViewController {
  
  @IBOutlet weak var profileImageView: UIImageView!
  @IBOutlet weak var displayNameTextField: UITextField!
  @IBOutlet weak var emailLabel: UILabel!
  @IBOutlet weak var tableView: UITableView!
  
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
  
  private var viewState: ViewState = .myItems {
    didSet {
      tableView.reloadData()
    }
  }
  
  // favorites data
  // TODO: create favorites model
  private var favorites = [String]() {
    didSet {
      DispatchQueue.main.async {
        self.tableView.reloadData()
      }
    }
  }
  
  private var myItems = [Item]() {
    didSet {
      DispatchQueue.main.async {
        self.tableView.reloadData()
      }
    }
  }
  
  private var refreshControl: UIRefreshControl!
  
  
  // myItems data
  
  override func viewDidLoad() {
    super.viewDidLoad()
    displayNameTextField.delegate = self
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(UINib(nibName: "ItemCell", bundle: nil), forCellReuseIdentifier: "itemCell")
    updateUI()
    fetchItems()
    refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: #selector(fetchItems), for: .valueChanged)
    tableView.refreshControl = refreshControl
    
  }
  
  @objc private func fetchItems() {
    guard let user = Auth.auth().currentUser else {
      refreshControl.endRefreshing()
      return
    }
    
    databaseService.fetchUserItems(userID: user.uid) { [weak self] (result) in
      switch result {
      case .failure(let error):
        DispatchQueue.main.async {
          self?.showAlert(title: "Error", message: error.localizedDescription)
        }
      case .success(let items):
        self?.myItems = items
      }
      DispatchQueue.main.async {
        self?.refreshControl.endRefreshing()
      }
    }
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
  
  
  @IBAction func segmentedControlPressed(_ sender: UISegmentedControl) {
    
    switch sender.selectedSegmentIndex {
    case 0:
      viewState = .myItems
      fetchItems()
    case 1:
      viewState = .favorites
    default:
      break
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

extension ProfileViewController : UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if viewState == .myItems {
      return myItems.count
    } else {
      return favorites.count
    }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as? ItemCell else {
      fatalError("Could not downcast to item Cell")
    }
    
    if viewState == .myItems {
      let item = myItems[indexPath.row]
      cell.configureCell(item)
    } else {
      let favorite = favorites[indexPath.row]
      //      cell.configureCell(favorite)
    }
    
    return cell
    
  }
  
}

extension ProfileViewController : UITableViewDelegate {
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 140
  }
}
