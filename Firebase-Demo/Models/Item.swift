//
//  Item.swift
//  Firebase-Demo
//
//  Created by Eric Davenport on 3/2/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import Foundation

struct Item {
  let itemName : String
  let price : Double
  let itemId : String
  let listedDate : Date
  let sellerName : String
  let sellerId : String
  let categoryName: String
}

extension Item {
    init(_ dictionary: [String: Any]) {
        self.itemName = dictionary["itemName"] as? String ?? "No item name"
        self.price = dictionary["price"] as? Double ?? 0.00
        self.itemId = dictionary["itemID"] as? String ?? "No Item ID"
        self.listedDate = dictionary["listedDate"] as? Date ?? Date()
        self.sellerName = dictionary["sellerName"] as? String ?? "No seller name"
        self.sellerId = dictionary["sellerID"] as? String ?? "No seller ID"
        self.categoryName = dictionary["categoryName"] as? String ?? "No category name"
    }
}
