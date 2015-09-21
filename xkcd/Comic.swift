//
//  Comic.swift
//  xkcd
//
//  Created by Evan Salter on 2015-09-17.
//  Copyright (c) 2015 Evan Salter. All rights reserved.
//

import Foundation

class Comic {
    
    var title: String = ""
    var link: String = ""
    var description: String = ""
    var date: String = ""
    var imageLink: String = ""
    var alt: String = ""
    var number: String = ""
    
    /// Create a dictionary of the object's variables for storing in user defaults
    ///
    /// - returns: `NSDictionary` containing all the variables of the object.
    func dictionary() -> NSDictionary {

        return["title":title,"link":link,"description":description,"date":date,"imageLink":imageLink,"alt":alt,"number":number]
        
    }
    
}