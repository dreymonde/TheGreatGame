//
//  NetworkActivity.swift
//  TheGreatGame
//
//  Created by Олег on 04.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import UIKit

public final class NetworkActivityIndicator {
    
    public static var isLogEnabled: Bool = false
    
    private func log(_ item: Any) {
        if NetworkActivityIndicator.isLogEnabled {
            print(item)
        }
    }
    
    private var counter = 0 {
        didSet {
            log("NetworkActivityCounter: \(counter)")
            assert(Thread.isMainThread)
            assert(counter >= 0)
            updateVisibility()
        }
    }
    
    private var visibilityTimer: TheGreatKit.Timer?
    private func updateVisibility() {
        if counter > 0 {
            show()
        } else {
            visibilityTimer = Timer(interval: 1.0) {
                self.hide()
            }
        }
    }
    
    private func cancelTimer() {
        visibilityTimer?.cancel()
        visibilityTimer = nil
    }
    
    private func show() {
        cancelTimer()
        _show()
    }
    
    private func hide() {
        cancelTimer()
        _hide()
    }
    
    private let _show: () -> ()
    private let _hide: () -> ()
    
    public init(show: @escaping () -> (),
                hide: @escaping () -> ()) {
        self._show = show
        self._hide = hide
    }
    
    public convenience init(setVisible: @escaping (Bool) -> ()) {
        self.init(show: { setVisible(true) }, hide: { setVisible(false) })
    }
    
    public func increment() {
        DispatchQueue.main.async {
            self.counter += 1
        }
    }
    
    public func decrement() {
        DispatchQueue.main.async {
            self.counter -= 1
        }
    }
    
    public static let none = NetworkActivityIndicator(setVisible: { _ in })
    
}

/// Essentially a cancellable `dispatch_after`.
fileprivate class Timer {
    // MARK: Properties
    
    fileprivate var isCancelled = false
    
    // MARK: Initialization
    
    init(interval: TimeInterval, handler: @escaping ()->()) {
        let when = DispatchTime.now() + interval
        DispatchQueue.main.asyncAfter(deadline: when) { [weak self] in
            if self?.isCancelled == false {
                handler()
            }
        }
    }
    
    func cancel() {
        isCancelled = true
    }
}
