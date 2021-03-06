//
//  ItemDetailController.swift
//  Firebase-Demo
//
//  Created by Eric Davenport on 3/11/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class ItemDetailController: UIViewController {
  
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var containerBottomConstraint: NSLayoutConstraint!
  @IBOutlet weak var commentTextField: UITextField!
  @IBOutlet weak var favoriteButton: UIBarButtonItem!
  
  private var item: Item
  private var originalValueForContraint: CGFloat = 0
  
  private var databaseService = DatabaseService()
  
  private lazy var tapGesture: UITapGestureRecognizer = {
    let gesture = UITapGestureRecognizer()
    gesture.addTarget(self, action: #selector(dismissKeyboard))
    return gesture
  }()
  
  private var isFavorite = false {
    didSet {
      if isFavorite {
        favoriteButton.image = UIImage(systemName: "heart.fill")
      } else {
        favoriteButton.image = UIImage(systemName: "heart")
      }
    }
  }
  
  private var listener: ListenerRegistration?
  
  private var comments = [Comment]() {
    didSet {
      DispatchQueue.main.async {
        self.tableView.reloadData()
      }
    }
  }
  
  private lazy var dateFormatter : DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE, MMM d, h:mm a"  // Wednesday, March 3, 2020 11:04
    return formatter
  }()
  
  // coming from storyboard requires coder in parameters
  init?(coder: NSCoder, item: Item) {
    self.item = item
    super.init(coder: coder)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder: ) has not been implemented")
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    updateUI()
    navigationItem.title = item.itemName
    commentTextField.delegate = self
    tableView.dataSource = self
    tableView.tableHeaderView = HeaderView(imageURL: item.imageURL)
    originalValueForContraint = containerBottomConstraint.constant
    view.addGestureRecognizer(tapGesture)
    navigationItem.largeTitleDisplayMode = .never
    
    // Refactor code (helper funtion) in viewDidLoad, we shpuld always strive for less code in or viewDidLoad
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(true)
    registerKeyboardNotifications()
    listener = Firestore.firestore().collection(DatabaseService.itemsCollection).document(item.itemId).collection(DatabaseService.commentsCollection).addSnapshotListener({ [weak self] (snapshot, error) in
      if let error = error {
        DispatchQueue.main.async {
          self?.showAlert(title: "Error", message: error.localizedDescription)
        }
      } else if let snapshot = snapshot {
        // create comments using dictionary initializer from the comment model
        let comments = snapshot.documents.map { Comment($0.data()) }
        // sort by date
        self?.comments = comments.sorted { $0.commentDate.dateValue() < $1.commentDate.dateValue()}
      }
    })
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(true)
    unregisterKeyboardNotifications()
  }
  
  private func updateUI() {
    // check if item is a favorite and update heart icon accordingly
    databaseService.isItemInFavorites(item: item) { [weak self] (result) in
      switch result {
      case .failure(let error):
        DispatchQueue.main.async {
          self?.showAlert(title: "Try again", message: error.localizedDescription)
        }
      case .success(let success):
        if success { // true
          self?.isFavorite = true
        } else {
          self?.isFavorite = false
        }
      }
    }
  }
  
  @IBAction func sendButtonPressed(_ sender: UIButton) {
    dismissKeyboard()
    
    guard let commentText = commentTextField.text,
      !commentText.isEmpty else {
        showAlert(title: "Missing Field", message: "Comment required")
        return
    }
    
    // post to firebase
    postComment(text: commentText)
    
  }
  
  @IBAction func favoriteButtonPressed(_ sender: UIBarButtonItem) {
    
    if isFavorite {  // remove from favorites
      databaseService.removeFromFavorites(item: item) { [weak self]  (result) in
        switch result {
        case .failure(let error):
          DispatchQueue.main.async {
            self?.showAlert(title: "failed to remove favorite", message: error.localizedDescription)
          }
        case .success:
          DispatchQueue.main.async {
            self?.showAlert(title: "Favorite removed", message: nil)
            self?.isFavorite = false
          }
          
        }
      }
    } else {  // not favorited - add to favoriteds
      databaseService.addToFavorites(item: item) { [weak self] (result) in
        switch result {
        case .failure(let error):
          DispatchQueue.main.async {
            self?.showAlert(title: "Favoriting Error", message: error.localizedDescription)
          }
        case .success:
          DispatchQueue.main.async {
            self?.showAlert(title: "Item favorited", message: nil)
            self?.isFavorite = true
          }
        }
      }
    }
    
    

  }
  
  
  private func postComment(text: String) {
    databaseService.postComment(item: item, comment: text) { [weak self] (result) in
      switch result {
      case .failure(let error):
        DispatchQueue.main.async {
          self?.showAlert(title: "Try Again", message: error.localizedDescription)
        }
      case .success:
        DispatchQueue.main.async {
          self?.showAlert(title: "Comment Posted", message: nil)
        }
      }
    }
  }
  
  private func registerKeyboardNotifications() {
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
  }
  
  private func unregisterKeyboardNotifications() {
    NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
  }
  
  @objc private func keyboardWillShow(_ notification: Notification) {
    print(notification.userInfo ?? "")
    guard let keyboardFrame = notification.userInfo?["UIKeyboardBoundsUserInfoKey"] as? CGRect else {
      return
    }
    // adjust the container view bottom constraint
    containerBottomConstraint.constant = -(keyboardFrame.height - view.safeAreaInsets.bottom)
  }
  
  @objc private func keyboardWillHide(_ notification: Notification) {
    dismissKeyboard()
  }
  
  
  @objc private func dismissKeyboard() {
    containerBottomConstraint.constant = originalValueForContraint
    commentTextField.resignFirstResponder()
  }
  
}

extension ItemDetailController : UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    dismissKeyboard()
    return true
  }
}


extension ItemDetailController : UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return comments.count
  }
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath)
    let comment = comments[indexPath.row]
    let dateString = dateFormatter.string(from: comment.commentDate.dateValue())
    cell.textLabel?.text = comment.text
    cell.detailTextLabel?.text = "@" + comment.commentedBy + " " + dateString
    return cell
  }
}

