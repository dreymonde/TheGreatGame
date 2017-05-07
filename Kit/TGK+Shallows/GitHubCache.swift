//
//  GitHubCache.swift
//  TheGreatGameDemo
//
//  Created by Олег on 03.05.17.
//
//

import Foundation
import Shallows

public enum Either<A, B> {
    case a(A)
    case b(B)
}

extension URLSession : ReadableCacheProtocol {
    
    public typealias Key = Either<URL, URLRequest>
    
    public enum CacheError : Error {
        case taskError(Error)
        case responseIsNotHTTP(URLResponse?)
        case noData
    }
    
    public func retrieve(forKey request: Key, completion: @escaping (Result<(HTTPURLResponse, Data)>) -> ()) {
        let completion: (Data?, URLResponse?, Error?) -> () = { (data, response, error) in
            if let error = error {
                completion(.failure(CacheError.taskError(error)))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(CacheError.responseIsNotHTTP(response)))
                return
            }
            guard let data = data else {
                completion(.failure(CacheError.noData))
                return
            }
            completion(.success(httpResponse, data))
        }
        let task: URLSessionTask
        switch request {
        case .a(let url):
            task = self.dataTask(with: url, completionHandler: completion)
        case .b(let request):
            task = self.dataTask(with: request, completionHandler: completion)
        }
        task.resume()
    }
    
}

public final class GitHubRepo : ReadableCacheProtocol {
    
    public typealias Key = String
    public typealias Value = Data
    
    public static let apiBase = URL(string: "https://api.github.com/repos/")!
    
    private let internalCache: ReadOnlyCache<String, Data>
    
    public init(owner: String, repo: String, networkCache: ReadOnlyCache<URL, Data>) {
        let base = GitHubRepo.apiBase.appendingPathComponent("\(owner)/\(repo)/").appendingPathComponent("contents/")
        print(base)
        self.internalCache = networkCache
            .mapJSONDictionary()
            .mapKeys({ printed(base.appendingPathComponent($0)) })
            .mapMappable(of: GitHubContentAPIResponse.self)
            .mapValues({ try $0.contentData.unwrap() })
    }
    
    public func retrieve(forKey key: String, completion: @escaping (Result<Data>) -> ()) {
        internalCache.retrieve(forKey: key, completion: completion)
    }
    
}

extension GitHubRepo {
    
    public static func theGreatGameStorage(networkCache: ReadOnlyCache<URL, Data>) -> GitHubRepo {
        return GitHubRepo(owner: "dreymonde", repo: "thegreatgame-storage", networkCache: networkCache)
    }
    
}

struct GitHubContentAPIResponse {
    
    enum Encoding : String {
        case base64
    }
    
    let content: String
    let encoding: Encoding
    
    var contentData: Data? {
        guard encoding == .base64 else {
            return nil
        }
        return Data(base64Encoded: content, options: .ignoreUnknownCharacters)
    }
    
}

extension GitHubContentAPIResponse : InMappable {
    
    enum MappingKeys : String, IndexPathElement {
        case content, encoding
    }
    
    init<Source>(mapper: InMapper<Source, MappingKeys>) throws where Source : InMap {
        self.content = try mapper.map(from: .content)
        self.encoding = try mapper.map(from: .encoding)
    }
    
}


extension ReadOnlyCache where Key == Either<URL, URLRequest> {
    
    public func usingURLKeys() -> ReadOnlyCache<URL, Value> {
        return mapKeys({ .a($0) })
    }
    
    public func usingURLRequestKeys() -> ReadOnlyCache<URLRequest, Value> {
        return mapKeys({ .b($0) })
    }
    
}

extension ReadOnlyCache where Value == (HTTPURLResponse, Data) {
    
    public func droppingResponse() -> ReadOnlyCache<Key, Data> {
        return mapValues({ $0.1 })
    }
    
}
