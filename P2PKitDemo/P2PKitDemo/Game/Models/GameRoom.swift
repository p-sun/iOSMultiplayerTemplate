//
//  GameRoom.swift
//  P2PKitDemo
//
//  Created by Paige Sun on 5/20/24.
//

import Foundation
import P2PKit
import UIKit

struct GameRoom: Codable {
    // Ids for currently connected Players
    let connectedIds: [Peer.Identifier]

    // Currently connected Players & their info
    var players: [Player] {
        connectedIds.compactMap { playerInfos[$0] }
    }
    
    // Historical info on all Players, for resuming the state of disconnected players
    private let playerInfos: [Peer.Identifier: Player]

    let nextPlayerHue: CGFloat
    
    static let empty: GameRoom = {
        return GameRoom(playerInfos: [:], connectedIDs: [], nextPlayerHue: 0.48)
    }()
    
    private init(playerInfos: [Peer.Identifier: Player], connectedIDs: [Peer.Identifier], nextPlayerHue: CGFloat) {
        self.nextPlayerHue = nextPlayerHue
        self.playerInfos = playerInfos
        self.connectedIds = connectedIDs
    }
    
    func withConnectedIDs(_ connectedIDs: [String]) -> GameRoom {
        return GameRoom(playerInfos: playerInfos, connectedIDs: connectedIDs, nextPlayerHue: nextPlayerHue)
    }
    
    func getPlayerByID(_ playerID: Peer.Identifier) -> Player? {
        return playerInfos[playerID]
    }
    
    func withNewPlayer(playerID: Peer.Identifier) -> GameRoom {
        let player = Player(
            playerID: playerID,
            score: 0,
            color: UIColor(hue: nextPlayerHue, saturation: 0.78, brightness: 0.8, alpha: 1))
        return self
            .withPlayer(player)
            .withHue((nextPlayerHue + 0.38).truncatingRemainder(dividingBy: 1))
    }
    
    func withPlayer(_ player: Player) -> GameRoom {
        var infos = playerInfos
        infos[player.playerID] = player
        return GameRoom(playerInfos: infos,
                        connectedIDs: connectedIds,
                        nextPlayerHue: nextPlayerHue)
    }
    
    func withHue(_ nextPlayerHue: CGFloat) -> GameRoom {
        return GameRoom(playerInfos: playerInfos,
                        connectedIDs: connectedIds,
                        nextPlayerHue: nextPlayerHue)
    }
}
