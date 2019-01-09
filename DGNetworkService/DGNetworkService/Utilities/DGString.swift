//
//  DGUtilities.swift
//  callbacRx
//
//  Created by Gmo Ginppian on 1/7/19.
//  Copyright © 2019 gonet. All rights reserved.
//

import Foundation

final class DGString {
    
    // Can't init is singleton
    private init() { }
    
    // MARK: Shared Instance
    static let shared = DGString()
    
    // MARK: Local Variable
    var empty = ""
}
