//
//  CreateItemViewController.swift
//  Firebase-Demo
//
//  Created by Eric Davenport on 3/2/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//


import UIKit
import FirebaseAuth
import FirebaseFirestore   // data base /// firestore

class CreateItemViewController: UIViewController {
  
  @IBOutlet weak var itemNameTextField: UITextField!
  @IBOutlet weak var itemPriceTextField: UITextField!
  @IBOutlet weak var itemImageView: UIImageView!
  
  private var category: Category
  private let dbService = DatabaseService()
  
  private let storageService = StorageService()
  
  private lazy var imagePickerController : UIImagePickerController = {
    let picker = UIImagePickerController()
    picker.delegate = self   // conform to UIPickerControllerDelegate amnd UINavigationControllerDelegate
    return picker
  }()
  
  private lazy var longPressGesture: UILongPressGestureRecognizer = {
    let gesture = UILongPressGestureRecognizer()
    gesture.addTarget(self, action: #selector(showPhotoOptions))
    return gesture
  }()
  
  private var selectedImage: UIImage? {
    didSet {
      itemImageView.image = selectedImage
    }
  }
  
  init?(coder: NSCoder, category: Category) {
    self.category = category
    super.init(coder: coder)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.title = category.name
    itemImageView.isUserInteractionEnabled = true
    itemImageView.addGestureRecognizer(longPressGesture)
    
  }
  
  @objc private func showPhotoOptions() {
    let alertController = UIAlertController(title: "Choose Photo Option", message: nil, preferredStyle: .actionSheet)
    let cameraAction = UIAlertAction(title: "Camera", style: .default) { (alertAction) in
      self.imagePickerController.sourceType = .camera
      self.present(self.imagePickerController, animated: true)
    }
    let photoLibrary = UIAlertAction(title: "Photo Library", style: .default) { (alertAction) in
      self.imagePickerController.sourceType = .photoLibrary
      self.present(self.imagePickerController, animated: true)
    }
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
    if UIImagePickerController.isSourceTypeAvailable(.camera) {
      alertController.addAction(cameraAction)
    }
    alertController.addAction(photoLibrary)
    alertController.addAction(cancelAction)
    present(alertController, animated: true)
    
  }
  
  @IBAction func sellButtonPressed(_ sender: UIBarButtonItem) {
    guard let itemName = itemNameTextField.text,
      !itemName.isEmpty,
      let priceText = itemPriceTextField.text,
      !priceText.isEmpty,
      let price = Double(priceText),
      let selectedImage = selectedImage else {
        showAlert(title: "Missing Fields", message: "All fields are required.")
        return
    }
    guard let displayName = Auth.auth().currentUser?.displayName else {
      showAlert(title: "Incomplete Profile", message: "Please go to profile to complete your settings")
      return
    }
    
    let resizedImage = UIImage.resizeImage(originalImage: selectedImage, rect: itemImageView.bounds)
    
    dbService.createItem(itemName: itemName, price: price, category: category, displayName: displayName) { [weak self] (result) in
      switch result {
      case .failure(let error):
        DispatchQueue.main.async {
          self?.showAlert(title: "Error creating item", message: "Something went wrong: \(error.localizedDescription)")
        }
      case .success(let documentID):
        // TODO: Upload photo to storage
        self?.uploadPhoto(image: resizedImage, documentID: documentID)
      }
    }
    
    //        dismiss(animated: true)
  }
  
  private func uploadPhoto(image: UIImage, documentID: String) {
    storageService.uploadPhoto(itemId: documentID, image: image) { [weak self] (result) in
      switch result {
      case .failure(let error):
        DispatchQueue.main.async {
          self?.showAlert(title: "Error uploading photo", message: "\(error.localizedDescription).")
        }
      case.success(let url):
        self?.updateItemImageURL(url, documentId: documentID)
      }
    }
  }
  
  private func updateItemImageURL(_ url: URL, documentId: String) {
    // update an existing document on firebase
    Firestore.firestore().collection(DatabaseService.itemsCollection).document(documentId).updateData(["imageURL" : url.absoluteString]) { [weak self] (error) in
      if let error = error {
        DispatchQueue.main.async {
          self?.showAlert(title: "Fail to update item", message: "\(error.localizedDescription)")
        }
      } else {
        // everything went okay
        print("all went well with the update")
        DispatchQueue.main.async {
          self?.dismiss(animated: true)
        }
      }
    }
  }
  
}

extension CreateItemViewController : UIImagePickerControllerDelegate , UINavigationControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
      fatalError("could not obtain original i age")
    }
    selectedImage = image
    dismiss(animated: true)
  }
}
