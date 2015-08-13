//
//  ViewModel.swift
//  AsyncDisplayKitHeaderNodeExample
//
//  Created by Ryan Fitzgerald on 8/13/15.
//  Copyright (c) 2015 ryanfitz. All rights reserved.
//

import Foundation

struct ViewModel: Hashable {
    let title : String
    
    var hashValue : Int {
        return title.hashValue
    }
}

func ==(lhs: ViewModel, rhs: ViewModel) -> Bool {
    return lhs.title == rhs.title
}