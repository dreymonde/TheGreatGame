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
    
    internal let session: WatchSessionManager
    public let pushKitReceiver: PushKitReceiver
    
    public init?(favoriteTeams: Retrieve<Set<Team.ID>>, favoriteMatches: Retrieve<Set<Match.ID>>) {
        guard let session = WatchSessionManager(favoriteTeams: favoriteTeams, favoriteMatches: favoriteMatches) else {
            return nil
        }
        self.session = session
        self.pushKitReceiver = PushKitReceiver()
    }
    
    public func declare(didUpdateFavoriteTeams: Subscribe<Set<Team.ID>>, didUpdateFavoriteMatches: Subscribe<Set<Match.ID>>) {
        session.declare(complicationMatchUpdate: pushKitReceiver.didReceiveIncomingPush.proxy
            .adapting(with: ComplicationPusher.adapter))
        session.feed(packages: didUpdateFavoriteTeams.map(FavoriteTeamsPackage.init))
        session.feed(packages: didUpdateFavoriteMatches.map(FavoriteMatchesPackage.init))
    }
    
}

public final class WatchSessionManager : NSObject, WCSessionDelegate {
    
    struct Sessions {
        let favoriteTeams: WatchTransferSession<Team.ID>
        let favoriteMatches: WatchTransferSession<Match.ID>
    }
    
    let favoriteTeams: Retrieve<Set<Team.ID>>
    let favoriteMatches: Retrieve<Set<Match.ID>>
    
    let session = WCSession.default()
    
    var activeSessios: Sessions?
    
    internal init?(favoriteTeams: Retrieve<Set<Team.ID>>, favoriteMatches: Retrieve<Set<Match.ID>>) {
        guard WCSession.isSupported() else {
            return nil
        }
        self.favoriteMatches = favoriteMatches
        self.favoriteTeams = favoriteTeams
        super.init()
        session.delegate = self
        session.activate()
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
    
    public func declare(complicationMatchUpdate: Subscribe<Match.Full>) {
        complicationMatchUpdate.flatMap({ try? $0.pack() })
            .subscribe(self, with: WatchSessionManager.sendComplicationUserInfo)
    }
    
    public func feed<Pack : AppleWatchPackable>(packages: Subscribe<Pack>) {
        packages.flatMap({ try? $0.pack() })
            .subscribe(self, with: WatchSessionManager.send)
    }
    
    let didSendPackage = Publisher<Package>(label: "WatchSessionManager.didSendPackage")
    let didFailToSendPackage = Publisher<Error>(label: "WatchSessionManager.didFailToSendPackage")
    
}

extension WatchSessionManager {
    
    var didSendUpdatedFavoriteTeams: Subscribe<Set<Team.ID>> {
        return didSendPackage.proxy
            .filter({ $0.kind == .favorite_teams })
            .flatMap({ try? FavoriteTeamsPackage.unpacked(from: $0) })
            .map({ $0.favs })
    }
    
    var didSendUpdatedFavoriteMatches: Subscribe<Set<Match.ID>> {
        return didSendPackage.proxy
            .filter({ $0.kind == .favorite_matches })
            .flatMap({ try? FavoriteMatchesPackage.unpacked(from: $0) })
            .map({ $0.favs })
    }
    
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
    
    private func makeSessions() -> Sessions? {
        guard let teams = WatchTransferSession<Team.ID>(session: session,
                                                        provider: favoriteTeams,
                                                        sendage: didSendUpdatedFavoriteTeams,
                                                        name: "favorite-teams-sendings") else {
                                                            return nil
        }
        guard let matches = WatchTransferSession<Match.ID>(session: session,
                                                          provider: favoriteMatches,
                                                          sendage: didSendUpdatedFavoriteMatches,
                                                          name: "favorite-matches-sendings") else {
                                                            return nil
        }
        return Sessions(favoriteTeams: teams, favoriteMatches: matches)
    }
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        printWithContext("\(activationState.rawValue) ; \(error as Any)")
        if activationState == .activated {
            if let newSessions = self.makeSessions() {
                self.activeSessios = newSessions
                feed(packages: newSessions.favoriteTeams.uploadConsistencyKeeper.shouldUploadFavorites.proxy
                    .map(FavoriteTeamsPackage.init))
                feed(packages: newSessions.favoriteMatches.uploadConsistencyKeeper.shouldUploadFavorites.proxy
                    .map(FavoriteMatchesPackage.init))
                newSessions.favoriteTeams.start()
                newSessions.favoriteMatches.start()
            } else {
                printWithContext("Cannot create new active session")
            }
        }
    }
    
}

internal final class WatchTransferSession<IDType : IDProtocol> where IDType.RawValue == Int {
    
    let session: WCSession
    let directoryURL: URL
    let directoryURLCache: RawFileSystemCache
    let uploadConsistencyKeeper: UploadConsistencyKeeper<Set<IDType>>
    
    init?(session: WCSession, provider: Retrieve<Set<IDType>>, sendage: Subscribe<Set<IDType>>, name: String) {
        guard session.activationState == .activated,
            let url = session.watchDirectoryURL else {
                return nil
        }
        self.session = session
        self.directoryURL = url
        self.directoryURLCache = RawFileSystemCache(directoryURL: url, qos: .background)
        let lastTransfer = directoryURLCache
            .mapJSONDictionary()
            .mapBoxedSet(of: IDType.self)
            .singleKey(.init(validFileName: "\(name).json"))
            .defaulting(to: [])
        self.uploadConsistencyKeeper = UploadConsistencyKeeper(actual: provider, lastUploaded: lastTransfer, name: name)
        uploadConsistencyKeeper.declare(didUploadFavorites: sendage)
    }
    
    func start() {
        printWithContext("Starting new active session \(self)")
        uploadConsistencyKeeper.check()
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
    
    init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
        self.wasPairedBefore = try mapper.map(from: .was_paired_before)
        self.sentInitialFavorites = try mapper.map(from: .sent_initial_favorites)
    }
    
    func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(self.wasPairedBefore, to: .was_paired_before)
        try mapper.map(self.sentInitialFavorites, to: .sent_initial_favorites)
    }
    
}
