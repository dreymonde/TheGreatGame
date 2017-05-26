//
//  Cell.swift
//  TheGreatGame
//
//  Created by Олег on 26.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit
import Avenues
import TheGreatKit

protocol CellFiller {
    
    associatedtype CellType
    associatedtype Content
    
    func setup(_ cell: CellType, with content: Content, forRowAt indexPath: IndexPath, afterImageDownload: Bool)
    
}

final class Cell<CellType : UITableViewCell, Content> : CellFiller {
    
    private let _setup: (CellType, Content, IndexPath, Bool) -> ()
    init(setup: @escaping (CellType, Content, IndexPath, Bool) -> ()) {
        self._setup = setup
    }
    
    func setup(_ cell: CellType, with content: Content, forRowAt indexPath: IndexPath, afterImageDownload: Bool) {
        _setup(cell, content, indexPath, afterImageDownload)
    }
    
}
