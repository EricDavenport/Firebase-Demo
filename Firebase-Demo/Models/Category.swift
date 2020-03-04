//
//  Category.swift
//  Firebase-Demo
//
//  Created by Eric Davenport on 3/2/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import Foundation
import  UIKit

struct Category {
  let image: UIImage
  let name: String
  
  public static func getCategories() -> [Category] {
    //return ["Electroics", "Home and Garden", "Fashion and Accessories", "Cars", "Motocycles and Other Vehicles", "Sports, Leisure and Games", "Baby and Child", "Movies, Books and Music", "Jobs", "Services", "Real Estate", "Other"]
    
    return [
      Category(image: UIImage(systemName: "speaker")!, name: "Electronics"),
      Category(image: UIImage(systemName: "bed.double.fill")!, name: "Home and Garden"),
      Category(image: UIImage(systemName: "scissors")!, name: "Fashion and Accessories"),
      
      Category(image: UIImage(systemName: "car")!, name: "Cars"),
      Category(image: UIImage(systemName: "airplane")!, name: "Motocycles and Other Vehicles"),
      Category(image: UIImage(systemName: "gamecontroller.fill")!, name: "Sports, Leisure and Games"),
      
      
      Category(image: UIImage(systemName: "smiley.fill")!, name: "Baby and Child"),
      Category(image: UIImage(systemName: "book")!, name: "Movies, Books and Music"),
      Category(image: UIImage(systemName: "wrench")!, name: "Jobs"),
      
      Category(image: UIImage(systemName: "paintbrush")!, name: "Services"),
      Category(image: UIImage(systemName: "house.fill")!, name: "Real Estate"),
      Category(image: UIImage(systemName: "tag")!, name: "Other"),    ]
  }
}
