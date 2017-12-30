//
//  ErrorDelegate.swift
//  TheGreatGame
//
//  Created by Олег on 28.12.2017.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation

public protocol ErrorStateDelegate : class {
    
    func errorDidOccur(_ error: Error)
    func errorDidNotOccur()
    
}

public class UnimplementedErrorStateDelegate : ErrorStateDelegate {
    
    public func errorDidOccur(_ error: Error) {
        printWithContext("Unimplemented")
    }
    
    public func errorDidNotOccur() {
        printWithContext("Unimplemented")
    }
    
    public static let shared = UnimplementedErrorStateDelegate()
    
}
