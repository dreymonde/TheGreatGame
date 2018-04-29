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
    let consistencyKeeper: UploadConsistencyKeeper<PushToken>
    
    public init(pusher: WriteOnlyStorage<Void, TokenUpload>,
                getDeviceIdentifier: @escaping () -> UUID?,
                consistencyKeepersStorage: Storage<Void, PushToken>,
                getToken: Retrieve<PushToken>) {
        self.pusher = pusher
        self.getDeviceIdentifier = getDeviceIdentifier
        self.consistencyKeeper = UploadConsistencyKeeper<PushToken>(latest: getToken, internalStorage: consistencyKeepersStorage, name: "token-uploader-consistency-keeper", reupload: { _ in })
        consistencyKeeper.reupload = self.upload(token:)
        consistencyKeeper.subscribeTo(didUpload: self.didUploadToken.proxy.map({ $0.token }))
    }
    
    public static func adapt(pusher: WriteOnlyStorage<Void, Data>) -> WriteOnlyStorage<Void, TokenUpload> {
        return pusher
            .mapJSONDictionary()
            .mapMappable()
    }
    
    public func subscribeTo(shouldCheckUploadConsistency: Subscribe<Void>) {
        shouldCheckUploadConsistency.subscribe(consistencyKeeper, with: UploadConsistencyKeeper.check)
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

