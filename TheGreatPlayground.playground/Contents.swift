//: Playground - noun: a place where people can play

import UIKit
import TheGreatKit

let session = URLSession.init(configuration: .ephemeral)
    .asReadOnlyCache()
    .usingURLKeys()
    .droppingResponse()
let repo = GitHubRawFilesRepo(owner: "dreymonde", repo: "thegreatgame-storage", networkCache: session).asReadOnlyCache()
let matchesAPI = MatchesAPI(dataProvider: repo).all.makeSyncCache()
let matches = try matchesAPI.retrieve()
print(matches)
