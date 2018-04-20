//
//  UploadKeeper.swift
//  TheGreatGame
//
//  Created by Oleg Dreyman on 13.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows
import Alba

internal final class UploadConsistencyKeeper<Upload : Equatable> {
    
    let latest: Retrieve<Upload>
    let lastUploaded: Storage<Void, Upload>
    let name: String
    
    var reupload: (Upload) -> ()
    
    init(latest: Retrieve<Upload>,
         internalStorage: Storage<Void, Upload>,
         name: String,
         reupload: @escaping (Upload) -> ()) {
        self.latest = latest
        self.lastUploaded = internalStorage
        self.name = name
        self.reupload = reupload
    }
    
    func subscribeTo(didUpload: Subscribe<Upload>) {
        didUpload.subscribe(self, with: UploadConsistencyKeeper.uploadDidHappen)
    }
    
    private func uploadDidHappen(_ upload: Upload) {
        lastUploaded.set(upload)
    }
    
    func check() {
        let name = self.name
        printWithContext("(uploads-\(name)) Checking if last update was properly uploaded")
        zip(latest, lastUploaded.asReadOnlyStorage()).retrieve { (result) in
            guard let (latest, uploaded) = result.value else {
                fault("(uploads-\(name)) Both caches should be defaulted")
                return
            }
            if uploaded != latest {
                self.reupload(latest)
            } else {
                printWithContext("(uploads-\(name)) It was")
            }
        }
    }
        
}
