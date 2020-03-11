//
//  ItemFeedViewController.swift
//  Firebase-Demo
//
//  Created by Chelsi Christmas on 3/2/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class ItemFeedViewController: UIViewController {
  
  @IBOutlet weak var tableView: UITableView!
  
  private var listener: ListenerRegistration?
  
  private var items = [Item]() {
    didSet {
      DispatchQueue.main.async {
        self.tableView.reloadData()
      }
    }
  }
  
  private let databaseService = DatabaseService()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(UINib(nibName: "ItemCell", bundle: nil), forCellReuseIdentifier: "itemCell")
  }
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(true)
    listener = Firestore.firestore().collection(DatabaseService.itemsCollection).addSnapshotListener({ [weak self] (snapshot, error) in
      if let error = error {
        DispatchQueue.main.async {
          self?.showAlert(title: "Firestore Error", message: "\(error.localizedDescription)")
        }
      } else if let snapshot = snapshot {
        print("There are \(snapshot.documents.count) item for sale")
        let items = snapshot.documents.map { Item($0.data()) }
        self?.items = items
      }
    })
  }
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(true)
    listener?.remove() // No longer are we listening for changes from Firebase
  }
}
extension ItemFeedViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 140
  }
}
extension ItemFeedViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as? ItemCell else {
      fatalError("Failed to dequeue as itemCell")
    }
    let item = items[indexPath.row]
    cell.configureCell(item)
    return cell
  }
  
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      // perform deletion on item
      let item = items[indexPath.row]
      databaseService.delete(item: item) { [weak self] (result) in
        switch result {
        case .failure(let error):
          DispatchQueue.main.async {
            self?.showAlert(title: "Deletion error", message: error.localizedDescription)
          }
        case .success:
          print("item deleted successfully")
        }
      }
    }
  }
  // on the clients side meaning the app we will make sure that swipe to delete only works for the uder who created the item
  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    let item = items[indexPath.row]
    guard let user = Auth.auth().currentUser else { return false }
    
    if item.sellerId != user.uid {
      return false    // unable to delete - cannot swipe om roew
    }
     return true   // able to delete tbis item
  }
  
  // TODO: thats not enough to only prevent accidental deletion on the client, we need to protect the database as well, we will do so using firebase "SecurityRules"
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let item = items[indexPath.row]
    let storyboard = UIStoryboard(name: "MainView", bundle: nil)
    let detailVC = storyboard.instantiateViewController(identifier: "ItemDetailController") { (coder) in
      return ItemDetailController(coder: coder, item: item)
    }
    navigationController?.pushViewController(detailVC, animated: true)
  }
  
}
