//
//  PushKitTokenUploader.swift
//  TheGreatGame
//
//  Created by Олег on 25.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows
import Alba

public final class TokenUploader {
    
    let getDeviceIdentifier: () -> UUID?
    let pusher: WriteOnlyStorage<Void, TokenUpload>
    let consistencyChecker: ConsistencyChecker<PushToken>
    
    public init(pusher: WriteOnlyStorage<Void, TokenUpload>,
                getDeviceIdentifier: @escaping () -> UUID?,
                serverMirror: Storage<Void, PushToken>,
                getToken: Retrieve<PushToken>) {
        self.pusher = pusher
        self.getDeviceIdentifier = getDeviceIdentifier
        self.consistencyChecker = ConsistencyChecker<PushToken>(truth: getToken,
                                                                destinationMirror: serverMirror,
                                                                name: "token-uploader")
        consistencyChecker.upload.delegate(to: self) { (self, token) in
            self.upload(token: token)
        }
    }
    
    public static func serverMirror(filename: Filename) -> Storage<Void, PushToken> {
        let defaultFakeToken = PushToken(Data(repeating: 0, count: 1))
        return Disk(directory: AppFolder.Library.Application_Support.Mirrors,
                    filenameEncoder: .noEncoding)
            .mapValues(transformIn: PushToken.init,
                       transformOut: { $0.rawToken })
            .singleKey(filename)
            .defaulting(to: defaultFakeToken)
            .asStorage()
    }
    
    public static func adapt(pusher: WriteOnlyStorage<Void, Data>) -> WriteOnlyStorage<Void, TokenUpload> {
        return pusher
            .mapJSONDictionary()
            .mapMappable()
    }
    
    public func subscribeTo(shouldCheckUploadConsistency: Subscribe<Void>) {
        shouldCheckUploadConsistency.subscribe(consistencyChecker, with: ConsistencyChecker.check)
    }
    
    let didUploadToken = Publisher<TokenUpload>(label: "TokenUploader.didUploadToken")
    
    func upload(token: PushToken) {
        guard let deviceID = getDeviceIdentifier() else {
            fault("No device UUID")
            return
        }
        let upload = TokenUpload(deviceIdentifier: deviceID, token: token)
        pusher.set(upload) { (result) in
            switch result {
            case .success:
                self.didUploadToken.publish(upload)
            case .failure(let error):
                printWithContext("Cannot upload token. Error: \(error)")
            }
        }
    }
    
}

public struct TokenUpload : Equatable {
    
    let deviceIdentifier: UUID
    let token: PushToken
    
    public init(deviceIdentifier: UUID, token: PushToken) {
        self.deviceIdentifier = deviceIdentifier
        self.token = token
    }
        
}

extension TokenUpload : Mappable {
    
    public enum MappingKeys : String, IndexPathElement {
        case device_identifier, token
    }
    
    public enum InMappingError : Error {
        case outMapOnly
    }
    
    public init<Source>(mapper: InMapper<Source, MappingKeys>) throws {
        throw InMappingError.outMapOnly
    }
    
    public func outMap<Destination>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(self.deviceIdentifier.uuidString, to: .device_identifier)
        try mapper.map(self.token.string, to: .token)
    }
    
}

