//
//  GitHubCache.swift
//  TheGreatGameDemo
//
//  Created by Олег on 03.05.17.
//
//

import Foundation
import Shallows

public final class GitHubRepo : ReadableCacheProtocol {
    
    public static let apiBase = URL(string: "https://api.github.com/repos/")!
    
    private let internalCache: ReadOnlyCache<APIPath, Data>
    
    public init(owner: String, repo: String, networkCache: ReadOnlyCache<URL, Data>) {
        let base = GitHubRepo.apiBase.appendingPathComponent("\(owner)/\(repo)/").appendingPathComponent("contents/")
        print("GitHub repo base:", base)
        self.internalCache = networkCache
            .mapJSONDictionary()
            .mapKeys({ base.appendingPath($0) })
            .mapMappable(of: GitHubContentAPIResponse.self)
            .mapValues({ try $0.contentData.unwrap() })
    }
    
    public func retrieve(forKey key: APIPath, completion: @escaping (Result<Data>) -> ()) {
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
