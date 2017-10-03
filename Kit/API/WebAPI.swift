import Foundation
import Shallows

public struct WebAPI : ReadableCacheProtocol {
        
    private let underlying: ReadOnlyCache<APIPath, Data>
    
    public init(networkProvider: ReadOnlyCache<URL, Data>,
                baseURL: URL) {
        self.underlying = networkProvider
            .mapKeys({ baseURL.appendingPath($0) })
    }
    
    public func retrieve(forKey key: APIPath, completion: @escaping (Result<Data>) -> ()) {
        underlying.retrieve(forKey: key, completion: completion)
    }
    
}

extension WebAPI {
    
    public init(urlSession: URLSession, baseURL: URL) {
        let networkProvider = urlSession.asReadOnlyCache()
            .droppingResponse()
            .usingURLKeys()
        self.init(networkProvider: networkProvider, baseURL: baseURL)
    }
    
}

extension URLSession : ReadableCacheProtocol {
    
    public enum Key {
        case url(URL)
        case urlRequest(URLRequest)
    }
    
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
        case .url(let url):
            task = self.dataTask(with: url, completionHandler: completion)
        case .urlRequest(let request):
            task = self.dataTask(with: request, completionHandler: completion)
        }
        task.resume()
    }
    
}

extension ReadOnlyCache where Key == URLSession.Key {
    
    public func usingURLKeys() -> ReadOnlyCache<URL, Value> {
        return mapKeys({ .url($0) })
    }
    
    public func usingURLRequestKeys() -> ReadOnlyCache<URLRequest, Value> {
        return mapKeys({ .urlRequest($0) })
    }
    
}

extension ReadOnlyCache where Value == (HTTPURLResponse, Data) {
    
    public func droppingResponse() -> ReadOnlyCache<Key, Data> {
        return mapValues({ $0.1 })
    }
    
}
