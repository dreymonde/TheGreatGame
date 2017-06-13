//
//  FavoriteTeamsUploader.swift
//  TheGreatGame
//
//  Created by Oleg Dreyman on 13.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Alba
import Shallows

final class PUSHer : CacheProtocol {
    
    typealias Key = URL
    typealias Value = Data
    
    let session: URLSession
    
    init(urlSession: URLSession) {
        self.session = urlSession
    }
    
    enum Error : Swift.Error {
        case writeOnly
        case statusCodeNot200(Int)
        case responseIsNotHTTP
        case clientError(Swift.Error)
        case noData
    }
    
    func retrieve(forKey key: URL, completion: @escaping (Result<Data>) -> ()) {
        completion(Result.failure(Error.writeOnly))
    }
    
    func set(_ value: Data, forKey key: URL, completion: @escaping (Result<Void>) -> ()) {
        var request = URLRequest(url: key)
        request.httpMethod = "POST"
        request.httpBody = value
        let task = session.dataTask(with: request) { (data, response, error) in
            printWithContext("Push finished")
            print("Is main thread:", Thread.isMainThread)
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

internal final class FavoritesUploader<IDType : IDProtocol> where IDType.RawValue == Int {
    
    let getNotificationsToken: Retrieve<PushToken>
    let getComplicationToken: Retrieve<PushToken>
    
    init(pusher: Cache<Void, Data>,
         getNotificationsToken: Retrieve<PushToken>,
         getComplicationToken: Retrieve<PushToken>) {
        self.pusher = pusher
            .mapJSONDictionary()
            .mapMappable()
        self.getNotificationsToken = getNotificationsToken
        self.getComplicationToken = getComplicationToken
    }
    
    let pusher: Cache<Void, FavoritesUpload<IDType>>
    
    internal func declare(didUpdateFavorites: SignedSubscribe<Set<IDType>>,
                          shouldUpdate_notifications: Subscribe<Set<IDType>>,
                          shouldUpdate_complication: Subscribe<Set<IDType>>) {
        didUpdateFavorites
            .drop(eventsSignedBy: self)
            .unsigned
            .flatSubscribe(self, with: { obj, event in obj.didUpdateFavorites(event, tokenType: .notifications); obj.didUpdateFavorites(event, tokenType: .complication) })
        shouldUpdate_notifications
            .flatSubscribe(self, with: { obj, event in obj.didUpdateFavorites(event, tokenType: .notifications) })
        shouldUpdate_complication
            .flatSubscribe(self, with: { obj, event in obj.didUpdateFavorites(event, tokenType: .complication) })
    }
    
    internal func didUpdateFavorites(_ update: Set<IDType>, tokenType: TokenType) {
        printWithContext()
        switch tokenType {
        case .notifications:
            self.uploadFavorites(update, usingTokenProvider: getNotificationsToken, tokenType: tokenType)
        case .complication:
            self.uploadFavorites(update, usingTokenProvider: getComplicationToken, tokenType: tokenType)
        }
    }
    
    private func uploadFavorites(_ favorites: Set<IDType>, usingTokenProvider provider: Retrieve<PushToken>, tokenType: TokenType) {
        provider.retrieve { (result) in
            if let token = result.value {
                let upload = FavoritesUpload(token: token, tokenType: tokenType, favorites: favorites)
                self.pusher.set(upload, completion: { (result) in
                    if let error = result.error {
                        printWithContext("Failed to write favorites \(favorites). Error: \(error)")
                    } else {
                        self.didUploadFavorites.publish(upload)
                    }
                })
            } else {
                printWithContext("No token for \(tokenType)")
            }
        }
    }
    
    let didUploadFavorites = Publisher<FavoritesUpload<IDType>>(label: "FavoriteTeamsUploader.didUploadFavorites")
    
}

internal enum TokenType : String {
    case notifications
    case complication
}

internal struct FavoritesUpload<IDType : IDProtocol> {
    
    let token: PushToken
    let tokenType: TokenType
    let favorites: Set<IDType>
    
}

extension FavoritesUpload : Mappable {
    
    enum MapError : Error {
        case outOnly
    }
    
    enum MappingKeys : String, IndexPathElement {
        case token, token_type, favorites
    }
    
    init<Source>(mapper: InMapper<Source, MappingKeys>) throws where Source : InMap {
        throw MapError.outOnly
    }
    
    func outMap<Destination>(mapper: inout OutMapper<Destination, MappingKeys>) throws where Destination : OutMap {
        try mapper.map(self.token.string, to: .token)
        try mapper.map(self.tokenType, to: .token_type)
        try mapper.map(Array(self.favorites), to: .favorites)
    }
    
}
