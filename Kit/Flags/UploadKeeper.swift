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

func destinationMirror<Flag : FlagDescriptor>(descriptor: Flag.Type) -> Storage<Void, FlagSet<Flag>> {
    let mirrorsURL = AppFolder.Library.Application_Support.Mirrors.url
    let storage = DiskFolderStorage(folderURL: mirrorsURL, filenameEncoder: .noEncoding)
        .singleKey(Flag.filename)
        .mapJSONDictionary()
        .mapFlagSet(of: Flag.self)
    return storage
}
