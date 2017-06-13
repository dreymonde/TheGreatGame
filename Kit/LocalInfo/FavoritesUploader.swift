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

extension Subscribe {
    
    public func dispatched(to queue: DispatchQueue) -> Subscribe<Event> {
        return rawModify(subscribe: { (id, handler) in
            self.manual.subscribe(objectWith: id, with: { (event) in
                queue.async { handler(event) }
            })
        }, entry: ProxyPayload.Entry.custom("redispatched"))
    }
    
}

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
    
    let rollback: (Favorites<IDType>.Update) -> ()
    let getNotificationsToken: () -> PushToken?
    let getComplicationToken: () -> PushToken?
    
    init(rollback: @escaping (Favorites<IDType>.Update) -> (),
         getNotificationsToken: @escaping () -> PushToken?,
         getComplicationToken: @escaping () -> PushToken?) {
        self.rollback = rollback
        self.getNotificationsToken = getNotificationsToken
        self.getComplicationToken = getComplicationToken
    }
    
    let pusher = PUSHer(urlSession: URLSession(configuration: .ephemeral))
        .mapJSONDictionary()
        .mapMappable(of: FavoritesUpload<IDType>.self)
        .mapKeys({
            let baseURL = URL.init(string: "https://the-great-game-ruby.herokuapp.com/favorites")!
            return baseURL
        })
    
    internal func declare(didUpdateFavorites: Subscribe<(Favorites<IDType>.Update, Set<IDType>)>) {
        didUpdateFavorites.subscribe(self, with: FavoritesUploader.didUpdateFavorites)
    }
    
    internal func didUpdateFavorites(_ favorites: (Favorites<IDType>.Update, Set<IDType>)) {
        let notification = getNotificationsToken().flatMap({ FavoritesUpload.init(token: $0, tokenType: .notificaions, favorites: favorites.1) })
        let complication = getComplicationToken().flatMap({ FavoritesUpload.init(token: $0, tokenType: .complication, favorites: favorites.1) })
        let uploads = [notification, complication].flatMap({ $0 })
        for upload in uploads {
            pusher.set(upload) { result in
                if let error = result.error {
                    printWithContext("Failed to write favorites, rolling back \(favorites.0). Error: \(error)")
                    self.rollback(favorites.0)
                } else {
                    self.didUploadFavorites.publish(upload)
                }
            }
        }
    }
    
    let didUploadFavorites = Publisher<FavoritesUpload<IDType>>(label: "FavoriteTeamsUploader.didUploadFavorites")
    
}

internal struct FavoritesUpload<IDType : IDProtocol> {
    
    internal enum TokenType : String {
        case notificaions
        case complication
    }
    
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
