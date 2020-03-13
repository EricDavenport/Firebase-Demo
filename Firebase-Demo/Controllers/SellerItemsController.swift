//
//  SellerItemsController.swift
//  Firebase-Demo
//
//  Created by Eric Davenport on 3/13/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import UIKit
import FirebaseFirestore

class SellerItemsController: UIViewController {
  
  @IBOutlet weak var tableView: UITableView!
  
  private var item: Item
  
  private var items = [Item]() {
    didSet {
      DispatchQueue.main.async {
        self.tableView.reloadData()
      }
    }
  }
  
  init?(coder: NSCoder, item: Item) {
    self.item = item
    super.init(coder: coder)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder: ) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.title = item.sellerName
    configureTableView()
    fetchItems()
    updateUserPhoto()
    
  }
  
  @objc private func fetchItems() {
    // TODO: refactor DatabaseServices tad StorageServices to a singleton since we are creating new instances through out application
    // MARK: Question - what type of functionality does this have - why is it a good action
    /*
     DatabaseServices{
     private init() {}
     static let shared = DatbaseService()
     }
     
     e.g DatabaseService.shared.function
     */
    
    DatabaseService().fetchUserItems(userID: item.sellerId) { (result) in
      switch result {
      case .failure(let error):
        DispatchQueue.main.async {
          self.showAlert(title: "Failed to load", message: error.localizedDescription)
        }
      case .success(let items):
        self.items = items
      }
    }
    
  }
  
  private func updateUserPhoto() {
    Firestore.firestore().collection(DatabaseService.usersCollection).document(item.sellerId).getDocument { [weak self] (snapshot, error) in
      // TODO: Vould be refactored to user model
      if let error = error {
        DispatchQueue.main.async {
          self?.showAlert(title: "Error fetch user", message: error.localizedDescription)
        }
      } else if let snapshot = snapshot {
        if let photoURL = snapshot.data()?["photoURL"] as? String {
          DispatchQueue.main.async {
            self?.tableView.tableHeaderView = HeaderView(imageURL: photoURL)
          }
        }
      }
    }
  }
  
  private func configureTableView() {
    tableView.tableHeaderView = HeaderView(imageURL: item.imageURL)
    tableView.register(UINib(nibName: "ItemCell", bundle: nil), forCellReuseIdentifier: "itemCell")
    tableView.dataSource = self
    tableView.delegate = self
  }
  
}

extension SellerItemsController : UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as? ItemCell else {
      fatalError("could not downcast to ItemCell")
    }
    let item = items[indexPath.row]
    cell.configureCell(for: item)
    return cell
  }
}

extension SellerItemsController : UITableViewDelegate {
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    // TODO: add constants file
    return 140
  }
}
