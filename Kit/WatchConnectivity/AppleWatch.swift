//
//  AppleWatch.swift
//  TheGreatGame
//
//  Created by Олег on 26.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import WatchConnectivity
import Alba
import Shallows

public final class AppleWatch {
    
    internal let sessionManager: WatchSessionManager
    public let pushKitReceiver: PushKitReceiver
    
    struct Sessions {
        let favoriteTeams: WatchTransferSession<Team.ID>
        let favoriteMatches: WatchTransferSession<Match.ID>
    }
    
    var activeSessions: Sessions?
    
    let favoriteTeams: Retrieve<Set<Team.ID>>
    let favoriteMatches: Retrieve<Set<Match.ID>>
    
    internal let sendPackage = Publisher<WatchSessionManager.Package>(label: "AppleWatch.sendPackages")
    
    public init?(favoriteTeams: Retrieve<Set<Team.ID>>, favoriteMatches: Retrieve<Set<Match.ID>>) {
        guard let session = WatchSessionManager(0) else {
            return nil
        }
        self.favoriteTeams = favoriteTeams
        self.favoriteMatches = favoriteMatches
        self.sessionManager = session
        self.pushKitReceiver = PushKitReceiver()
    }
    
    public func subscribeTo(didUpdateFavoriteTeams: Subscribe<Set<Team.ID>>, didUpdateFavoriteMatches: Subscribe<Set<Match.ID>>) {
        sessionManager.activationDidComplete.proxy.subscribe(self, with: AppleWatch.updateSessions)
        let push = pushKitReceiver.didReceiveIncomingPush.proxy
            .adapting(with: ComplicationPusher.adapter)
            .flatMap({ try? $0.pack() })
        sessionManager.subscribeTo(userInfo: self.sendPackage.proxy,
                               complicationUserInfo: push)
        didUpdateFavoriteTeams.subscribe(self, with: AppleWatch.favoriteTeamsDidUpdate)
        didUpdateFavoriteMatches.subscribe(self, with: AppleWatch.favoriteMatchesDidUpdate)
    }
    
    func favoriteTeamsDidUpdate(_ favoriteTeams: Set<Team.ID>) {
        activeSessions?.favoriteTeams.transfer(favoriteTeams)
    }
    
    func favoriteMatchesDidUpdate(_ favoriteMatches: Set<Match.ID>) {
        activeSessions?.favoriteMatches.transfer(favoriteMatches)
    }
    
    func send<IDType : IDProtocol>(_ ids: Set<IDType>) where IDType.RawValue == Int, IDType : AppleWatchPackableElement {
        if let package = try? IDPackage(ids).pack() {
            sendPackage.publish(package)
        }
    }
    
    func updateSessions(after activation: WatchSessionManager.Activation) {
        if let activeSessions = makeSessions(with: activation) {
            self.activeSessions = activeSessions
            activeSessions.favoriteMatches.start()
            activeSessions.favoriteTeams.start()
        }
    }
    
    func makeSessions(with activation: WatchSessionManager.Activation) -> Sessions? {
        guard let teams = WatchTransferSession<Team.ID>(activation: activation,
                                                        provider: favoriteTeams,
                                                        sendage: sessionManager.didSendPackage.proxy.adapting(with: IDPackage.adapter),
                                                        name: "favorite-teams-sendings",
                                                        performTransfer: self.send) else {
                                                            return nil
        }
        guard let matches = WatchTransferSession<Match.ID>(activation: activation,
                                                           provider: favoriteMatches,
                                                           sendage: sessionManager.didSendPackage.proxy.adapting(with: IDPackage.adapter),
                                                           name: "favorite-matches-sendings",
                                                           performTransfer: self.send) else {
                                                            return nil
        }
        return Sessions(favoriteTeams: teams, favoriteMatches: matches)
    }
    
}

public final class WatchSessionManager : NSObject, WCSessionDelegate {
    
    let session = WCSession.default
    
    internal init?(_ flag: UInt8) {
        guard WCSession.isSupported() else {
            return nil
        }
        super.init()
        session.delegate = self
        session.activate()
    }
    
    func subscribeTo(userInfo: Subscribe<Package>,
                 complicationUserInfo: Subscribe<Package>) {
        userInfo.subscribe(self, with: WatchSessionManager.send)
        complicationUserInfo.subscribe(self, with: WatchSessionManager.sendComplicationUserInfo)
    }
    
    public func send(_ package: Package) {
        guard session.activationState == .activated else {
            printWithContext("Session is not active")
            return
        }
        do {
            let rawPackage = try package.map() as [String : Any]
            session.transferUserInfo(rawPackage)
            printWithContext("Sending package \(package.kind)...")
        } catch {
            didFailToSendPackage.publish(error)
        }
    }
    
    public func sendComplicationUserInfo(_ package: Package) {
        do {
            let rawPackage = try package.map()
            session.transferCurrentComplicationUserInfo(rawPackage)
            printWithContext("Updating complication user info...")
        } catch {
            didFailToSendPackage.publish(error)
        }
    }
    
    let didSendPackage = Publisher<Package>(label: "WatchSessionManager.didSendPackage")
    let didFailToSendPackage = Publisher<Error>(label: "WatchSessionManager.didFailToSendPackage")
    let activationDidComplete = Publisher<WatchSessionManager.Activation>(label: "WatchSessionManager.activationDidComplete")
    let activationDidFail = Publisher<Error>(label: "WatchSessionManager.actiovationDidFail")
    
}

extension WatchSessionManager {
    
    public func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        do {
            let package = try Package(from: userInfoTransfer.userInfo)
            if let error = error {
                self.didFailToSendPackage.publish(error)
            } else {
                self.didSendPackage.publish(package)
            }
        } catch {
            fault("Invalid package reported: \(userInfoTransfer)")
        }
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
        printWithContext()
    }
    
    public func sessionDidBecomeInactive(_ session: WCSession) {
        printWithContext()
    }
    
    struct Activation {
        let state: WCSessionActivationState
        let watchDirectoryURL: URL
    }
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        printWithContext("\(activationState.rawValue) ; \(error as Any)")
        guard error == nil else {
            activationDidFail.publish(error!)
            return
        }
        guard let url = session.watchDirectoryURL else {
            fault("No watch directory URL")
            return
        }
        let activation = Activation(state: activationState, watchDirectoryURL: url)
        activationDidComplete.publish(activation)
    }
    
}

internal final class WatchTransferSession<IDType : IDProtocol> where IDType.RawValue == Int {
    
    let directoryURL: URL
    let directoryURLCache: RawFileSystemStorage
    
    private let uploadConsistencyKeeper: UploadConsistencyKeeper<Set<IDType>>
    
    private let performTransfer: (Set<IDType>) -> ()
    
    init?(activation: WatchSessionManager.Activation, provider: Retrieve<Set<IDType>>, sendage: Subscribe<Set<IDType>>, name: String, performTransfer: @escaping (Set<IDType>) -> ()) {
        guard activation.state == .activated else {
                return nil
        }
        let url = activation.watchDirectoryURL
        self.directoryURL = url
        self.directoryURLCache = RawFileSystemStorage(directoryURL: url, qos: .background)
        let lastTransfer = directoryURLCache
            .mapJSONDictionary()
            .mapBoxedSet(of: IDType.self)
            .singleKey(.init(validFileName: Filename(rawValue: "\(name).json")))
            .defaulting(to: [])
        self.uploadConsistencyKeeper = UploadConsistencyKeeper(latest: provider, internalStorage: lastTransfer, name: name, reupload: performTransfer)
        self.performTransfer = performTransfer
        uploadConsistencyKeeper.subscribeTo(didUpload: sendage)
    }
    
    func start() {
        printWithContext("Starting new active session \(self)")
        uploadConsistencyKeeper.check()
    }
    
    func transfer(_ ids: Set<IDType>) {
        self.performTransfer(ids)
    }
    
}

internal struct AppleWatchInfo {
    
    var wasPairedBefore: Bool
    var sentInitialFavorites: Bool
    
    init(wasPairedBefore: Bool, sentInitialFavorites: Bool) {
        self.wasPairedBefore = wasPairedBefore
        self.sentInitialFavorites = sentInitialFavorites
    }
    
    static var blank: AppleWatchInfo {
        return AppleWatchInfo(wasPairedBefore: false, sentInitialFavorites: false)
    }
    
}

extension AppleWatchInfo : Mappable {
    
    enum MappingKeys : String, IndexPathElement {
        case was_paired_before, sent_initial_favorites
    }
    
    init<Source>(mapper: InMapper<Source, MappingKeys>) throws {
        self.wasPairedBefore = try mapper.map(from: .was_paired_before)
        self.sentInitialFavorites = try mapper.map(from: .sent_initial_favorites)
    }
    
    func outMap<Destination>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(self.wasPairedBefore, to: .was_paired_before)
        try mapper.map(self.sentInitialFavorites, to: .sent_initial_favorites)
    }
    
}
