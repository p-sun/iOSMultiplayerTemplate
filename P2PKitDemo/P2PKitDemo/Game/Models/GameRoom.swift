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
            color: UIColor(hue: nextPlayerHue, saturation: 0.8, brightness: 0.8, alpha: 1))
        return self
            .withPlayer(player)
            .withHue((nextPlayerHue + 0.37).truncatingRemainder(dividingBy: 1))
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
    
    static let initialLocalState: GameRoom = {
        return GameRoom(
            playerInfos: ["Player 1": Player(playerID: "Player 1", score: 0, color: #colorLiteral(red: 0.5386788845, green: 0.3363381028, blue: 0.9497646689, alpha: 1)),
                          "Player 2": Player(playerID: "Player 2", score: 0, color: #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)),
                          "Player 3": Player(playerID: "Player 3", score: 0, color: #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1))],
            connectedIDs: ["Player 1", "Player 2", "Player 3"],
            nextPlayerHue: 0.83)
    }()
}
