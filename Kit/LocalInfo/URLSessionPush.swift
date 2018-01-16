//
//  URLSessionPush.swift
//  TheGreatGame
//
//  Created by Олег on 25.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows

public final class PUSHer : WritableStorageProtocol {
    
    public typealias Key = URL
    public typealias Value = Data
    
    let session: URLSession
    
    public init(urlSession: URLSession) {
        self.session = urlSession
    }
    
    public enum Error : Swift.Error {
        case writeOnly
        case statusCodeNot200(Int)
        case responseIsNotHTTP
        case clientError(Swift.Error)
        case noData
    }
        
    public func set(_ value: Data, forKey key: URL, completion: @escaping (Result<Void>) -> ()) {
        var request = URLRequest(url: key)
        request.httpMethod = "POST"
        request.httpBody = value
        let task = session.dataTask(with: request) { (data, response, error) in
            printWithContext("Push finished")
            guard error == nil else {
                completion(Result.failure(error!))
                return
            }
            guard let response = response as? HTTPURLResponse else {
                completion(Result.failure(Error.responseIsNotHTTP))
                return
            }
            guard response.statusCode == 200 else {
                completion(Result.failure(Error.statusCodeNot200(response.statusCode)))
                return
            }
            guard let data = data else {
                completion(Result.failure(Error.noData))
                return
            }
            printWithContext(String.init(data: data, encoding: .utf8))
            completion(.success)
        }
        task.resume()
    }
    
}
