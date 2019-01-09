//
//  ViewController.swift
//  DGNetworkService
//
//  Created by Gmo Ginppian on 1/8/19.
//  Copyright © 2019 gonet. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let r = Request()
        r.httpPost(url: "https://jsonplaceholder.typicode.com/posts",
                   bodyData: ["title": "foo", "body": "bar", "userId": 1]) { (requestError, requestJson) in
                    
                    if let json = requestJson {
                        print(json)
                        
                        let body = json["body"] as? String ?? DGString.shared.empty
                        print("body: \(body)")
                        
                        let title = json["title"] as? String ?? DGString.shared.empty
                        print("title: \(title)")
                        
                        let userId = json["userId"] as? NSNumber ?? 0
                        print("userId: \(userId)")
                        
                        let id = json["id"] as? NSNumber ?? 0
                        print("id: \(id)")
                        
                    } else {
                        print(requestError)
                    }
        }

    }

}
