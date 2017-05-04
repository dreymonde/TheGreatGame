
struct CocoaAny {
    var value: Any
}

extension CocoaAny : InMap {
    
    func get<T>() -> T? {
        return value as? T
    }
    
    func get(at indexPath: IndexPathValue) -> CocoaAny? {
        switch indexPath {
        case .key(let key):
            if let dict = value as? [String: Any] {
                return dict[key].map(CocoaAny.init)
            }
            return nil
        case .index(let index):
            if let array = value as? [Any],
                array.indices.contains(index) {
                return CocoaAny(value: array[index])
            }
            return nil
        }
    }
    
    var int: Int? {
        return value as? Int
    }
    
    var string: String? {
        return value as? String
    }
    
    var double: Double? {
        return value as? Double
    }
    
    var bool: Bool? {
        return value as? Bool
    }
    
    func asArray() -> [CocoaAny]? {
        if let array = value as? [[String: Any]] {
            return array.map(CocoaAny.init)
        }
        if let array = value as? [Any] {
            return array.map(CocoaAny.init)
        }
        return nil
    }
    
}

public enum CocoaOutMappingError : Error {
    case notDictionary
    case notArray
}

extension CocoaAny : OutMap {
    
    mutating func set(_ map: CocoaAny, at indexPath: IndexPathValue) throws {
        let newValue = map.value
        switch indexPath {
        case .key(let key):
            if var dict = value as? [String: Any] {
                dict[key] = newValue
                self.value = dict
                return
            }
            throw CocoaOutMappingError.notDictionary
        case .index(let index):
            if var array = value as? [Any],
                array.indices.contains(index) {
                array[index] = newValue
                self.value = array
                return
            }
            throw CocoaOutMappingError.notArray
        }
    }
    
    static func fromArray(_ array: [CocoaAny]) -> CocoaAny? {
        return CocoaAny(value: array.map({ $0.value }))
    }
    
    static func from<T>(_ value: T) -> CocoaAny? {
        return CocoaAny(value: value)
    }
    
    static func from(_ int: Int) -> CocoaAny? {
        return CocoaAny(value: int)
    }
    
    static func from(_ double: Double) -> CocoaAny? {
        return CocoaAny(value: double)
    }
    
    static func from(_ string: String) -> CocoaAny? {
        return CocoaAny(value: string)
    }
    
    static func from(_ bool: Bool) -> CocoaAny? {
        return CocoaAny(value: bool)
    }
    
    static var blank: CocoaAny {
        return CocoaAny(value: [String: Any]())
    }
    
}

extension InMappable {
    
    /// Creates instance from `dict`.
    public init(from dict: [String: Any]) throws {
        let mapper = InMapper<CocoaAny, MappingKeys>(of: .init(value: dict))
        try self.init(mapper: mapper)
    }
    
}

extension BasicInMappable {
    
    /// Creates instance from `dict`.
    public init(from dict: [String: Any]) throws {
        let mapper = BasicInMapper<CocoaAny>(of: .init(value: dict))
        try self.init(mapper: mapper)
    }
    
}

extension InMappableWithContext {
    
    /// Creates instance from `dict` using given context.
    public init(from dict: [String: Any], withContext context: MappingContext) throws {
        let mapper = ContextualInMapper<CocoaAny, MappingKeys, MappingContext>(of: .init(value: dict), context: context)
        try self.init(mapper: mapper)
    }
    
}

extension OutMappable {
    
    /// Maps `self` to `[String: Any]` dictionary.
    ///
    /// - parameter destination: instance to map to. Leave it .blank if you want to create your instance from scratch.
    ///
    /// - throws: `OutMapperError`.
    ///
    /// - returns: `[String: Any]` dictionary created from `self`.
    public func map() throws -> [String: Any] {
        var mapper = OutMapper<CocoaAny, MappingKeys>()
        try outMap(mapper: &mapper)
        if let dict = mapper.destination.value as? [String: Any] {
            return dict
        }
        throw CocoaOutMappingError.notDictionary
    }
    
}

extension BasicOutMappable {
    
    /// Maps `self` to `[String: Any]` dictionary.
    ///
    /// - parameter destination: instance to map to. Leave it .blank if you want to create your instance from scratch.
    ///
    /// - throws: `OutMapperError`.
    ///
    /// - returns: `[String: Any]` dictionary created from `self`.
    public func map() throws -> [String: Any] {
        var mapper = BasicOutMapper<CocoaAny>()
        try outMap(mapper: &mapper)
        if let dict = mapper.destination.value as? [String: Any] {
            return dict
        }
        throw CocoaOutMappingError.notDictionary
    }
    
}

extension OutMappableWithContext {
    
    /// Maps `self` to `[String: Any]` dictionary using `context`.
    ///
    /// - parameter destination: instance to map to. Leave it .blank if you want to create your instance from scratch.
    /// - parameter context:     use `context` to describe the way of mapping.
    ///
    /// - throws: `OutMapperError`.
    ///
    /// - returns: `[String: Any]` dictionary created from `self`.
    public func map(withContext context: MappingContext) throws -> [String: Any] {
        var mapper = ContextualOutMapper<CocoaAny, MappingKeys, MappingContext>(context: context)
        try outMap(mapper: &mapper)
        if let dict = mapper.destination.value as? [String: Any] {
            return dict
        }
        throw CocoaOutMappingError.notDictionary
    }
    
}
