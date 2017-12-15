//
//  GitHubCache.swift
//  TheGreatGameDemo
//
//  Created by Олег on 03.05.17.
//
//

import Foundation
import Shallows

public final class GitHubRawFilesRepo : ReadableStorageProtocol {
    
    public static let apiBase = URL(string: "https://raw.githubusercontent.com/")!
    
    private let internalCache: ReadOnlyStorage<APIPath, Data>
    
    public init(owner: String, repo: String, networkCache: ReadOnlyStorage<URL, Data>) {
        let base = GitHubRawFilesRepo.apiBase.appendingPath(APIPath.init(components: [owner, repo, "master", "content"]))
        self.internalCache = networkCache
            .mapKeys(to: APIPath.self, { path in base.appendingPath(path) })
    }
    
    public func retrieve(forKey key: APIPath, completion: @escaping (Result<Data>) -> ()) {
        internalCache.retrieve(forKey: key, completion: completion)
    }
    
}

extension GitHubRawFilesRepo {
    
    public static func theGreatGameStorage(networkCache: ReadOnlyStorage<URL, Data>) -> GitHubRawFilesRepo {
        return GitHubRawFilesRepo(owner: "dreymonde", repo: "thegreatgame-storage", networkCache: networkCache)
    }
    
}

public final class GitHubRepo : ReadableStorageProtocol {
    
    public static let apiBase = URL(string: "https://api.github.com/repos/")!
    
    private let internalCache: ReadOnlyStorage<APIPath, Data>
    
    public init(owner: String, repo: String, networkCache: ReadOnlyStorage<URL, Data>) {
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
    
    public static func theGreatGameStorage(networkCache: ReadOnlyStorage<URL, Data>) -> GitHubRepo {
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
    
    init<Source>(mapper: InMapper<Source, MappingKeys>) throws {
        self.content = try mapper.map(from: .content)
        self.encoding = try mapper.map(from: .encoding)
    }
    
}
