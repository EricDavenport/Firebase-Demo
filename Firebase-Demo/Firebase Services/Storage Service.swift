//
//  Storage Service.swift
//  Firebase-Demo
//
//  Created by Eric Davenport on 3/4/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import Foundation
import FirebaseStorage

class StorageService {
  
  // in our app we will be uploading a photo to storage in two places:
  //    1. ProfileViewCOntroller
  //    2. CreateItemViewController
  
  // we will be creating two different buckets of folders
  //    1. UserProfilePhotos/user.uid
  //    2. ItemsPhoto/itemId
  
  // let's create a reference to the firebase storage
  private let storageRef = Storage.storage().reference()
  
  // default parameters in Swiftg e.g userId: String? = nil
  public func uploadPhoto(userId: String? = nil, itemId: String? = nil, image: UIImage, completion: @escaping (Result<URL, Error>) -> ()) {
    // MARK: Question -
    /*
     Why didnt we pass in a user in order to asign userId to photo or itemid to user?
     */
    
    // 1. COnvert UIImage to data because this is the object we are posting to Fireba Storage
    guard let imageData = image.jpegData(compressionQuality: 1.0) else {
      return
    }
    
    // we need to establish which bucket or collection or folder we will be saving the photo to
    var photoReference : StorageReference!
    
    // guardiing against if object has userId or itemId
    if let userId = userId { // coming from ProfileViewController
      photoReference = storageRef.child("UserProfilePhotos/\(userId).jpg")
    } else if let itemId = itemId {  // coming from CreateItemViewController
      photoReference = storageRef.child("itemsPhotos/\(itemId).jpg")
    }
    // configure metadata for the objecct being uploaded
    let metadata = StorageMetadata()
    metadata.contentType = "image/jpg"
    
    let _ = photoReference.putData(imageData, metadata: metadata) { (metaData, error) in
      if let error = error {
        completion(.failure(error))
      } else if let _ = metaData {
        photoReference.downloadURL { (url, error2) in
          if let error2 = error2 {
            completion(.failure(error2))
          } else if let url = url {
            completion(.success(url))
          }
        }
      }
      
    }
    
    
  }
}
