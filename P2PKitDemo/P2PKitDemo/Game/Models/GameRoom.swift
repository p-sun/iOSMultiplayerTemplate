//
//  GameRoom.swift
//  P2PKitDemo
//
//  Created by Paige Sun on 5/20/24.
//

import Foundation
import P2PKit

struct GameRoom: Codable {
    let nextPlayerHue: CGFloat
    let playerInfos: [Peer.Identifier: Player]
    let connectedIds: [Peer.Identifier]
    var players: [Player] {
        connectedIds.compactMap { playerInfos[$0] }
    }
    
    init(playerInfos: [Peer.Identifier: Player], connectedIDs: [Peer.Identifier], nextPlayerHue: CGFloat) {
        self.nextPlayerHue = nextPlayerHue
        self.playerInfos = playerInfos
        self.connectedIds = connectedIDs
    }
    
    static func createEmpty() -> GameRoom {
        GameRoom(playerInfos: [:], connectedIDs: [], nextPlayerHue: 0.83)
    }
    
    static func createMock() -> GameRoom {
        GameRoom(
            playerInfos: ["Player 1": Player(playerID: "Player 1", score: 0, color: #colorLiteral(red: 0.5386788845, green: 0.3363381028, blue: 0.9497646689, alpha: 1)),
                          "Player 2": Player(playerID: "Player 2", score: 0, color: #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)),
                          "Player 3": Player(playerID: "Player 3", score: 0, color: #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1))],
            connectedIDs: ["Player 1", "Player 2", "Player 3"],
            nextPlayerHue: 0.83)
    }
}
