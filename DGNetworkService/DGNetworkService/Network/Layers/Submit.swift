//
//  Submit.swift
//  DGNetworkService
//
//  Created by Gmo Ginppian on 1/8/19.
//  Copyright © 2019 gonet. All rights reserved.
//

import Foundation

class Submit: NSObject {
    
    private var session: URLSession?
    private var dataTask: URLSessionDataTask?
    
    override init() {
        super.init()
        session = URLSession(configuration: .default)
    }
    
    internal func submit(request: URLRequest,
                completion: @escaping (_ error: String, _ json: NSDictionary?) -> Void)
        -> Void {
        
        dataTask = session?.dataTask(with: request, completionHandler: { (data, response, error) in
            
            guard error == nil else {
                completion("🔴🔴🔴 ERROR :: \(error?.localizedDescription ?? DGString.shared.empty)", nil)
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                
                switch httpResponse.statusCode {
                case 200...299:
                    print("🔵🔵🔵 SUCCESS :: Status: \(httpResponse.statusCode)")
                    break
                case 400...499:
                    completion("🔴🔴🔴 ERROR :: Error de comunicaciones, favor de reintentar mas tarde\n...Status Code: \(httpResponse.statusCode)", nil)
                    return
                case 500...599:
                    completion("🔴🔴🔴 ERROR :: Servicio no disponible, favor de reintentar mas tarde\n...Status Code: \(httpResponse.statusCode)", nil)
                    return
                default:
                    completion("🔴🔴🔴 ERROR :: Cuidado, entró en default statusCode: \(httpResponse.statusCode)", nil)
                    return
                }
            }
            else { // Response nil
                completion("🔴🔴🔴 ERROR :: No llego nada del response: \(String(describing: response))", nil)
                return
            }
            if let data = data {
                do {
                    // Puede ser un arreglo
                    if let rawArr = try JSONSerialization.jsonObject(with: data, options: []) as? NSArray {
                        let dic: NSDictionary = ["genericList": rawArr]
                        completion(DGString.shared.empty, dic)
                    }
                    else if let rawDic = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                        completion(DGString.shared.empty, rawDic)
                    }
                    else {
                        completion("🔴🔴🔴 ERROR :: Error al castear el json", nil)
                    }
                    
                } catch let error {
                    completion("🔴🔴🔴 ERROR :: Cargar Json - \(error.localizedDescription)", nil)
                }
            } else {
                completion("🔴🔴🔴 ERROR :: Data es Nulo", nil)
            }
        })
        dataTask?.resume()
    }
}
