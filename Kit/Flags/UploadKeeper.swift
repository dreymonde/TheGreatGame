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

internal final class ConsistencyChecker<T : Equatable> {
    
    let truth: Retrieve<T>
    let destinationMirror: Storage<Void, T>
    let name: String
    
    var upload = Delegated<T, Void>()
    
    init(truth: Retrieve<T>, destinationMirror: Storage<Void, T>, name: String) {
        self.truth = truth
        self.destinationMirror = destinationMirror
        self.name = name
    }
    
    func subcribeTo(didUpload: Subscribe<T>) {
        didUpload.subscribe(self, with: ConsistencyChecker.uploadDidHappen)
    }
    
    private func uploadDidHappen(_ uploadedValue: T) {
        self.destinationMirror.set(uploadedValue)
    }
    
    func check() {
        let name = self.name
        printWithContext("(uploads-\(name)) Checking if last update was properly uploaded")
        zip(truth, destinationMirror.asReadOnlyStorage()).retrieve { (result) in
            guard let (trueValue, currentValue) = result.value else {
                fault("(uploads-\(name)) Both caches should be defaulted")
                return
            }
            if trueValue != currentValue {
                self.upload.call(trueValue)
            } else {
                printWithContext("(uploads-\(name)) It was")
            }
        }
    }
    
}

func destinationMirror<T : Mappable>(identifier: String) -> Storage<Void, T> {
    let mirrorsURL = AppFolder.Library.Application_Support.Mirrors.url
    let storage = DiskFolderStorage(folderURL: mirrorsURL, filenameEncoder: .noEncoding)
        .singleKey(Filename(rawValue: identifier))
        .mapJSONDictionary()
        .mapMappable(of: T.self)
    return storage
}

internal final class UploadConsistencyKeeper<Upload : Equatable> {
    
    let latest: Retrieve<Upload>
    let lastUploaded: Storage<Void, Upload>
    let name: String
    
    var reupload: (Upload) -> ()
    
    init(latest: Retrieve<Upload>,
         internalStorage: Storage<Void, Upload>,
         name: String,
         reupload: @escaping (Upload) -> () = { _ in }) {
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
