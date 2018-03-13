//
//  TCK+UserDefaults.swift
//  The Cleaning App
//
//  Created by Олег on 15.03.17.
//  Copyright © 2017 Two-212 Apps. All rights reserved.
//

import Foundation

public struct UserDefaultsKey<Value> : Hashable {
    
    public var rawValue: String
    
    public init(_ key: String) {
        self.rawValue = key
    }
    
    static public func == (lhs: UserDefaultsKey<Value>, rhs: UserDefaultsKey<Value>) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
    public var hashValue: Int {
        return rawValue.hashValue
    }
    
}

public protocol UserDefaultsDefaultRetrievable {
    
    static func retrieveNonOptional(from userDefaults: UserDefaults) -> (_ key: String) -> Self
    
}

extension Bool : UserDefaultsDefaultRetrievable {
    
    public static func retrieveNonOptional(from userDefaults: UserDefaults) -> (String) -> Bool {
        return userDefaults.bool(forKey:)
    }
    
}

extension Int : UserDefaultsDefaultRetrievable {
    
    public static func retrieveNonOptional(from userDefaults: UserDefaults) -> (String) -> Int {
        return userDefaults.integer(forKey:)
    }
    
}

extension Double : UserDefaultsDefaultRetrievable {
    
    public static func retrieveNonOptional(from userDefaults: UserDefaults) -> (String) -> Double {
        return userDefaults.double(forKey:)
    }
    
}

extension UserDefaults {

    public func value<Value>(forKey key: UserDefaultsKey<Value>) -> Value? {
        return value(forKey: key.rawValue) as? Value
    }
    
    public func value<Value : UserDefaultsDefaultRetrievable>(forKey key: UserDefaultsKey<Value>) -> Value {
        return Value.retrieveNonOptional(from: self)(key.rawValue)
    }
    
    public func value<Value : InMappable>(forKey key: UserDefaultsKey<Value>) -> Value? {
        guard let dict = dictionary(forKey: key.rawValue) else { return nil }
        return try? Value(from: dict)
    }
    
    public func value<Value : RawRepresentable>(forKey key: UserDefaultsKey<Value>) -> Value? where Value.RawValue == String {
        return string(forKey: key.rawValue)
            .flatMap(Value.init(rawValue:))
    }
    
}

extension UserDefaults {
    
    public func set<Value>(_ value: Value?, forKey key: UserDefaultsKey<Value>) {
        set(value, forKey: key.rawValue)
    }
    
    public func set<Value : OutMappable>(_ value: Value?, forKey key: UserDefaultsKey<Value>) {
        let dict: [String : Any]? = value.flatMap({ try? $0.map() })
        set(dict, forKey: key.rawValue)
    }
    
    public func set<Value : RawRepresentable>(_ value: Value?, forKey key: UserDefaultsKey<Value>) {
        set(value?.rawValue, forKey: key.rawValue)
    }
    
}

extension UserDefaults {
    
    public func remove<Value>(atKey key: UserDefaultsKey<Value>) {
        removeObject(forKey: key.rawValue)
    }
    
}

public struct LaunchArgumentKey<Value> : Hashable {
    
    public var rawValue: String
    
    public init(_ key: String) {
        self.rawValue = key
    }
    
    static public func == (lhs: LaunchArgumentKey<Value>, rhs: LaunchArgumentKey<Value>) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
    public var hashValue: Int {
        return rawValue.hashValue
    }
    
}

public func launchArgument<Value>(_ key: LaunchArgumentKey<Value>) -> Value? {
    let userDefaultsKey = UserDefaultsKey<Value>(key.rawValue)
    let value = UserDefaults.standard.value(forKey: userDefaultsKey)
    print(key.rawValue, value as Any)
    printWithContext("\(key.rawValue) \(String.init(describing: value))")
    return value
}

public func launchArgument<Value : UserDefaultsDefaultRetrievable>(_ key: LaunchArgumentKey<Value>) -> Value {
    let userDefaultsKey = UserDefaultsKey<Value>(key.rawValue)
    let value = UserDefaults.standard.value(forKey: userDefaultsKey)
    printWithContext("\(key.rawValue) \(String.init(describing: value))")
    return value
}

public func launchArgument<Value : RawRepresentable>(_ key: LaunchArgumentKey<Value>) -> Value? {
    let userDefaultsKey = UserDefaultsKey<Value.RawValue>(key.rawValue)
    let value = UserDefaults.standard.value(forKey: userDefaultsKey).flatMap(Value.init(rawValue:))
    printWithContext("\(key.rawValue) \(String.init(describing: value))")
    return value
}
