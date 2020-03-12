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
  static let usersCollection = "users"
  static let commentsCollection = "comments"   // sub-collection on an item document
  static let favoritesCollection = "favorites"
  
  // review firebase works like this
  // top level
  // collection -> document ->collection -> documnt ->.....
  
  // lets get a reference to the Firebase Firestore database
  
  private let db = Firestore.firestore()
  
  public func createItem(itemName: String, price: Double, category: Category, displayName: String, completion: @escaping (Result<String, Error>) -> ()) {
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
        completion(.success(documentRef.documentID))
      }
      
    }
  }
  
  public func createDatabaseUser(authDataResult: AuthDataResult, completion: @escaping (Result<Bool, Error>) -> ()) {
    
    guard let email = authDataResult.user.email else { return }
    
    db.collection(DatabaseService.usersCollection).document(authDataResult.user.uid).setData(["email": email,
                                                                                              "createdDate": Timestamp(date: Date()),
                                                                                              "userID": authDataResult.user.uid]) { (error) in
                                                                                                if let error = error {
                                                                                                  completion(.failure(error))
                                                                                                } else {
                                                                                                  completion(.success(true))
                                                                                                }
    }
  }
  
  func updateDatabaseUser(displayName: String, photoURL: String, completion: @escaping (Result<Bool, Error>) -> ()) {
    guard let user = Auth.auth().currentUser else { return }
    
    db.collection(DatabaseService.usersCollection).document(user.uid).updateData(["photoURL": photoURL, "displayName": displayName]) { (error) in
      if let error = error {
        completion(.failure(error))
      } else {
        completion(.success(true))
      }
    }
  }
  
  public func delete(item: Item, completion: @escaping (Result<Bool, Error>) -> ()) {
    db.collection(DatabaseService.itemsCollection).document(item.itemId).delete() { (error) in
      if let error = error {
        completion(.failure(error))
      } else {
        completion(.success(true))
      }
      
    }
  }
  
  public func postComment(item: Item, comment: String, completion: @escaping (Result<Bool, Error>) -> () ){
    guard let user = Auth.auth().currentUser,
      let displayName = user.displayName else {
        print("please update profile with display name")
        return
    }
    // getting the document
    let docRef = db.collection(DatabaseService.itemsCollection).document(item.itemId).collection(DatabaseService.commentsCollection).document()
    // using document from above to write to its contents to firebase
    db.collection(DatabaseService.itemsCollection).document(item.itemId).collection(DatabaseService.commentsCollection).document(docRef.documentID).setData(["text": comment, "commentDate": Timestamp(date: Date()), "itemName": item.itemName, "itemID": item.itemId, "sellerName": item.sellerName, "commentedBy": displayName]) { (error) in
      if let error = error {
        completion(.failure(error))
      } else {
        completion(.success(true))
      }
    }
  }
  
  public func addToFavorites(item: Item, completion: @escaping (Result<Bool, Error>) -> ()){
    guard let user = Auth.auth().currentUser else { return }
    db.collection(DatabaseService.usersCollection).document(user.uid).collection(DatabaseService.favoritesCollection).document(item.itemId).setData(["itemName" : item.itemName, "price": item.price, "imageURL": item.imageURL, "favoritedDate": Timestamp(date: Date()), "itemId": item.itemId, "sellerName": item.sellerName, "sellerId": item.sellerId]) { (error) in
      
      if let error = error {
        completion(.failure(error))
      } else {
        completion(.success(true))
      }
    }
  }
  
  public func removeFromFavorites(item: Item, completion: @escaping (Result<Bool, Error>) -> ()) {
    guard let user = Auth.auth().currentUser else { return }
    
    db.collection(DatabaseService.usersCollection).document(user.uid).collection(DatabaseService.favoritesCollection).document(item.itemId).delete { (error) in
      if let error  = error {
        completion(.failure(error))
      } else {
        completion(.success(true))
      }
    }
  }
  
  
  public func isItemInFavorites(item: Item, completion: @escaping (Result<Bool, Error>) -> ()) {
    guard let user = Auth.auth().currentUser else { return }
    
    // in Firebase we use the "where" keyword to query (search) a collection
    
    // addSnapshotListener - continues to listen for modifications to a collection
    // addDocuments - fetches documents ONLY once
    db.collection(DatabaseService.usersCollection).document(user.uid).collection(DatabaseService.favoritesCollection).whereField("itemId", isEqualTo: item.itemId).getDocuments { (snapshot, error) in
      if let error = error {
        completion(.failure(error))
      } else if let snapshot = snapshot {
        let count = snapshot.documents.count
        // MARK: confusion - why take the cout and let that determine if this is false or not
        
        if count > 0 {
          completion(.success(true))
        } else {
          completion(.success(false))
        }
      }
    }
  }
  
  
  public func fetchUserItems(userID: String, completion: @escaping (Result<[Item], Error>) -> ()) {
    db.collection(DatabaseService.itemsCollection).whereField("sellerID", isEqualTo: userID).getDocuments { (snapshot, error) in
      if let error = error {
        completion(.failure(error))
      } else if let snapshot = snapshot {
        let items = snapshot.documents.map { Item($0.data()) }
        completion(.success(items))
      }
    }
  }
  
  
}
