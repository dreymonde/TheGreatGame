
import Foundation

public typealias MapProtocol = InMap & OutMap
public typealias Mappable = InMappable & OutMappable

extension URL : Mappable {
    
    public init<Source>(mapper: PlainInMapper<Source>) throws {
        let urlString: String = try mapper.map()
        if let url = URL(string: urlString) {
            self = url
        } else {
            throw URLError(.badURL)
        }
    }
    
    public func outMap<Destination>(mapper: inout OutMapper<Destination, NoKeys>) throws {
        try mapper.map(self.absoluteString)
    }
    
}

extension Date : Mappable {
    
    public typealias MappingKeys = NoKeys
    
    public init<Source>(mapper: InMapper<Source, NoKeys>) throws {
        let ti = try mapper.map() as TimeInterval
        self = Date.init(timeIntervalSince1970: ti)
    }
    
    public func outMap<Destination>(mapper: inout OutMapper<Destination, NoKeys>) throws {
        try mapper.map(self.timeIntervalSince1970)
    }
    
}
