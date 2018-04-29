//
//  NetworkErrorHandling.swift
//  TheGreatGame
//
//  Created by Oleg Dreyman on 07.12.2017.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import UIKit
import TheGreatKit
import Whisper

protocol NetworkErrorDisplaying { }

fileprivate var alreadyShowingError = false

extension NetworkErrorDisplaying where Self : UIViewController {
    
    func displayError() {
        assert(Thread.isMainThread)
        printWithContext()
        let message = Murmur(title: "Offline mode. The information can be irrelevant.", backgroundColor: UIColor.init(named: .errorMessageBackground), titleColor: .white)
        if !alreadyShowingError {
            Whisper.show(whistle: message, action: .show(5))
            alreadyShowingError = true
        }
    }
    
    func hideError() {
        assert(Thread.isMainThread)
        printWithContext()
        let message = Murmur(title: "Online!", backgroundColor: UIColor.init(named: .onlineMessageBackground), titleColor: .white)
        if alreadyShowingError {
            Whisper.show(whistle: message, action: .show(5))
            alreadyShowingError = false
        }
    }
    
}
