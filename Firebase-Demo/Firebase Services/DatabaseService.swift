//
//  DatabaseService.swift
//  Firebase-Demo
//
//  Created by Eric Davenport on 3/2/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//


import Foundation
import FirebaseFirestore
import FirebaseAuth

class DatabaseService {
    // static let to ensure the collection name is consistent
    static let itemsCollection = "items"
    
    private let db = Firestore.firestore()
    
    public func createItem(itemName: String, price: Double, category: Category, displayName: String, completion: @escaping (Result<Bool, Error>) -> ()) {
        guard let user = Auth.auth().currentUser else { return }
        // Generating a document for the items collection (in firebase database)
        let documentRef = db.collection(DatabaseService.itemsCollection).document()
        // create a document in our "items" collection
        // the Firebase database takes in data with dictionaries, so we set the data to match our model
        // Providing a "documentRef" allows us to assign an id to the data, allowing us to use this for easy reference
        db.collection(DatabaseService.itemsCollection).document(documentRef.documentID).setData(["itemName": itemName,"price": price,"itemID": documentRef.documentID,"listedDate": Timestamp(date: Date()),"sellerName": displayName,"sellerID": user.uid,"categoryName": category.name]) {
            (error) in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(true))
            }
            
        }
    }
    
}
