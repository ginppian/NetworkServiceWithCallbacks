//
//  DGUtilities.swift
//  callbacRx
//
//  Created by Gmo Ginppian on 1/7/19.
//  Copyright © 2019 gonet. All rights reserved.
//

import Foundation

public class DGUtilities: NSObject {
    
    public class var TimeOutInterval: TimeInterval {
        return 30.0
    }
    
    public class var BasicHeaderFields: [String: String] {
        return ["Accept": "application/json",
                "Content-Type": "application/json",
                "LAN": "cocoatouch"]
    }
}
