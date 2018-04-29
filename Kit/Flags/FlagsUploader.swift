//
//  FavoriteTeamsUploader.swift
//  TheGreatGame
//
//  Created by Oleg Dreyman on 13.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Alba
import Shallows

internal final class FlagsUploader<Flag : FlagDescriptor> {
    
    typealias IDType = Flag.IDType
    
    let getNotificationsToken: Retrieve<PushToken>
    let getDeviceIdentifier: () -> UUID?
    
    init(pusher: WriteOnlyStorage<Void, FlagsUpload<Flag>>,
         getNotificationsToken: Retrieve<PushToken>,
         getDeviceIdentifier: @escaping () -> UUID?) {
        self.pusher = pusher
        self.getNotificationsToken = getNotificationsToken
        self.getDeviceIdentifier = getDeviceIdentifier
    }
    
    internal static func adapt(pusher: WriteOnlyStorage<Void, Data>) -> WriteOnlyStorage<Void, FlagsUpload<Flag>> {
        return pusher
            .mapJSONDictionary()
            .mapMappable()
    }
    
    let pusher: WriteOnlyStorage<Void, FlagsUpload<Flag>>
    
    func uploadFavorites(_ update: FlagSet<Flag>) {
        printWithContext()
        uploadFlags(update, usingTokenProvider: getNotificationsToken)
    }
    
    private func uploadFlags(_ flags: FlagSet<Flag>, usingTokenProvider provider: Retrieve<PushToken>) {
        guard let deviceIdentifier = getDeviceIdentifier() else {
            fault("No device UUID")
            return
        }
        provider.retrieve { (result) in
            if let token = result.value {
                let upload = FlagsUpload(deviceIdentifier: deviceIdentifier,
                                         token: token,
                                         flags: flags)
                self.upload(upload: upload)
            } else {
                printWithContext("No token for notifications")
            }
        }
    }
    
    private func upload(upload: FlagsUpload<Flag>) {
        self.pusher.set(upload) { (result) in
            if let error = result.error {
                printWithContext("Failed to upload \(upload). Error: \(error)")
            } else {
                self.didUpload.publish(upload)
            }
        }
    }
    
    let didUpload = Publisher<FlagsUpload<Flag>>(label: "FlagsUploader<\(Flag.self)>.didUploadFavorites")
    
    internal var didUploadFlags: Subscribe<FlagSet<Flag>> {
        return didUpload.proxy.map({ $0.flags })
    }
    
}

internal struct FlagsUpload<Flag : FlagDescriptor> {
    
    let deviceIdentifier: UUID
    let token: PushToken
    let flags: FlagSet<Flag>
    
}

extension FlagsUpload : Mappable {
    
    enum MapError : Error {
        case outOnly
    }
    
    enum MappingKeys : String, IndexPathElement {
        case token, favorites, device_identifier
    }
    
    init<Source>(mapper: InMapper<Source, MappingKeys>) throws {
        throw MapError.outOnly
    }
    
    func outMap<Destination>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(self.deviceIdentifier.uuidString, to: .device_identifier)
        try mapper.map(self.token.string, to: .token)
        try mapper.map(Array(self.flags.set), to: .favorites)
    }
    
}
