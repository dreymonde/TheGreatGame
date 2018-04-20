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
        let favoriteTeams: WatchTransferSession<FavoriteTeams>
        let favoriteMatches: WatchTransferSession<FavoriteMatches>
    }
    
    var activeSessions: Sessions?
    
    let favoriteTeams: Retrieve<FavoriteTeams.Set>
    let favoriteMatches: Retrieve<FavoriteMatches.Set>
    
    internal let sendPackage = Publisher<WatchSessionManager.Package>(label: "AppleWatch.sendPackages")
    
    public init?(favoriteTeams: Retrieve<FavoriteTeams.Set>,
                 favoriteMatches: Retrieve<FavoriteMatches.Set>) {
        guard let session = WatchSessionManager(()) else {
            return nil
        }
        self.favoriteTeams = favoriteTeams
        self.favoriteMatches = favoriteMatches
        self.sessionManager = session
        self.pushKitReceiver = PushKitReceiver()
    }
    
    public func subscribeTo(didUpdateFavoriteTeams: Subscribe<FavoriteTeams.Set>,
                            didUpdateFavoriteMatches: Subscribe<FavoriteMatches.Set>) {
        sessionManager.activationDidComplete.proxy.subscribe(self, with: AppleWatch.updateSessions)
        let didReceiveIncomingMatchPushPackage = pushKitReceiver.didReceiveIncomingPush.proxy
            .adapting(with: pushToMatch)
            .map({ try! $0.pack() })
        didUpdateFavoriteTeams.subscribe(self, with: AppleWatch.favoriteTeamsDidUpdate)
        didUpdateFavoriteMatches.subscribe(self, with: AppleWatch.favoriteMatchesDidUpdate)
        didReceiveIncomingMatchPushPackage.subscribe(sessionManager, with: WatchSessionManager.sendComplicationUserInfo)
    }
    
    func favoriteTeamsDidUpdate(_ favoriteTeams: FavoriteTeams.Set) {
        activeSessions?.favoriteTeams.transfer(favoriteTeams)
    }
    
    func favoriteMatchesDidUpdate(_ favoriteMatches: FavoriteMatches.Set) {
        activeSessions?.favoriteMatches.transfer(favoriteMatches)
    }
    
    func updateSessions(after activation: WatchSessionManager.Activation) {
        if let activeSessions = makeSessions(with: activation) {
            self.activeSessions = activeSessions
            activeSessions.favoriteMatches.start()
            activeSessions.favoriteTeams.start()
        }
    }
    
    func makeSessions(with activation: WatchSessionManager.Activation) -> Sessions? {
        guard let teams = WatchTransferSession<FavoriteTeams>(
            activation: activation,
            provider: favoriteTeams,
            sendage: sessionManager.didSendPackage.proxy.adapting(with: IDPackage.packageToIDsSet),
            name: "favorite-teams-sendings",
            performTransfer: sessionManager.send) else {
                return nil
        }
        guard let matches = WatchTransferSession<FavoriteMatches>(
            activation: activation,
            provider: favoriteMatches,
            sendage: sessionManager.didSendPackage.proxy.adapting(with: IDPackage.packageToIDsSet),
            name: "favorite-matches-sendings",
            performTransfer: sessionManager.send) else {
                return nil
        }
        return Sessions(favoriteTeams: teams, favoriteMatches: matches)
    }
    
}

public final class WatchSessionManager : NSObject, WCSessionDelegate {
    
    let session = WCSession.default
    
    internal init?(_ void: Void) {
        guard WCSession.isSupported() else {
            return nil
        }
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

internal final class WatchTransferSession<Flag : FlagDescriptor> where Flag : AppleWatchPackableElement {
    
    let directoryURLCache: DiskFolderStorage
    private let uploadConsistencyKeeper: UploadConsistencyKeeper<FlagsSet<Flag>>
    
    internal let transfer: (FlagsSet<Flag>) -> ()
    
    init?(activation: WatchSessionManager.Activation,
          provider: Retrieve<FlagsSet<Flag>>,
          sendage: Subscribe<FlagsSet<Flag>>,
          name: String,
          performTransfer: @escaping (WatchSessionManager.Package) -> ()) {
        guard activation.state == .activated else {
            return nil
        }
        let url = activation.watchDirectoryURL
        self.directoryURLCache = DiskFolderStorage(folderURL: url, filenameEncoder: .noEncoding)
        let lastTransfer = directoryURLCache
            .mapJSONDictionary()
            .mapFlagsSet(of: Flag.self)
            .singleKey(Filename(rawValue: "\(name).json"))
            .defaulting(to: FlagsSet([]))
        
        let perform: (FlagsSet<Flag>) -> () = { flags in
            performTransfer(package(from: flags))
        }
        self.transfer = perform
        self.uploadConsistencyKeeper = UploadConsistencyKeeper<FlagsSet<Flag>>(
            latest: provider,
            internalStorage: lastTransfer,
            name: name,
            reupload: perform
        )
        uploadConsistencyKeeper.subscribeTo(didUpload: sendage)
    }
    
    func start() {
        printWithContext("Starting new active session \(self)")
        uploadConsistencyKeeper.check()
    }
    
}

func package<Flag : FlagDescriptor>(from flags: FlagsSet<Flag>) -> WatchSessionManager.Package where Flag : AppleWatchPackableElement {
    let package = try! IDPackage(flags).pack()
    return package
}

