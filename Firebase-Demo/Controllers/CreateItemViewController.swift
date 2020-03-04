//
//  CreateItemViewController.swift
//  Firebase-Demo
//
//  Created by Eric Davenport on 3/2/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//


import UIKit
import FirebaseAuth

class CreateItemViewController: UIViewController {
    
    @IBOutlet weak var itemNameTextField: UITextField!
    @IBOutlet weak var itemPriceTextField: UITextField!
    
    private var category: Category
    private let dbService = DatabaseService()
    
    
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
        
    }
    
    @IBAction func postItem(_ sender: UIBarButtonItem) {
        guard let itemName = itemNameTextField.text,
            !itemName.isEmpty,
            let priceText = itemPriceTextField.text,
            !priceText.isEmpty,
            let price = Double(priceText) else {
                showAlert(title: "Missing Fields", message: "All fields are required.")
                return
        }
        guard let displayName = Auth.auth().currentUser?.displayName else {
            showAlert(title: "Incomplete Profile", message: "Please go to profile to complete your settings")
            return
        }
        dbService.createItem(itemName: itemName, price: price, category: category, displayName: displayName) { [weak self] (result) in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                self?.showAlert(title: "Error creating item", message: "Something went wrong: \(error.localizedDescription)")
                }
            case .success:
                DispatchQueue.main.async {
                self?.showAlert(title: nil, message: "Successfully listed your item: \(itemName)")
                }
            }
        }
        
//        dismiss(animated: true)
    }


}
