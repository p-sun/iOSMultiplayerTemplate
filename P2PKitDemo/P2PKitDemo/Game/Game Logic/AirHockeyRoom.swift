//
//  AirHockeyRoom.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/12/24.
//

import Foundation
import UIKit
import P2PKit
import MultipeerConnectivity

protocol GameRoomPlayerDelegate: AnyObject {
    func gameRoomPlayersDidChange(_ gameRoom: GameRoom)
}

class GameRoom {
    weak var delegate: GameRoomPlayerDelegate? {
        didSet {
            delegate?.gameRoomPlayersDidChange(self)
        }
    }
    
    // All players including self
    var players: [Player] {
        return syncedPlayers.value
    }
    
    private let syncedPlayers = P2PSynced<[Player]>(name: "SyncedPlayers", initial: [], reliable: true)

    init() {
        P2PNetwork.addPeerDelegate(self)
        P2PNetwork.start()
        
        syncedPlayers.onReceiveSync = { [weak self] players in
            guard let self = self else { return }
            delegate?.gameRoomPlayersDidChange(self)
        }
        
        self.syncedPlayers.value = [
            createPlayer(from: Peer(MCPeerID(displayName: "Player 1"), id: "111")),
            createPlayer(from: Peer(MCPeerID(displayName: "Player 2"), id: "222")),
            createPlayer(from: Peer(MCPeerID(displayName: "Player 3"), id: "333"))
        ]
    }
}

// MARK: - Host Only

extension GameRoom {
    func incrementScore(_ playerID: Peer.Identifier) {
        guard P2PNetwork.isHost else { return }
        
        var players = syncedPlayers.value
        if let i = players.firstIndex(where: { $0.playerID == playerID }) {
            players[i] = Player(
                playerID: players[i].playerID,
                score: players[i].score + 1,
                color: players[i].color)
            syncedPlayers.value = players
        }
    }
    
    private func getOrCreateGamePlayer(from peer: Peer) -> Player {
        if let i = syncedPlayers.value.firstIndex(where: { player in
                player.playerID == peer.id }) {
            return players[i]
        } else {
            return createPlayer(from: peer)
        }
    }
    
    private static var nextHue: CGFloat = 0.83
    private func createPlayer(from peer: Peer) -> Player {
        let player = Player(
            playerID: peer.id,
            score: 0,
            color: UIColor(hue: GameRoom.nextHue, saturation: 0.8, brightness: 0.8, alpha: 1))
        GameRoom.nextHue = (GameRoom.nextHue + 0.37).truncatingRemainder(dividingBy: 1)
        return player
    }
}

extension GameRoom: P2PNetworkPeerDelegate {
    func p2pNetwork(didUpdate peer: Peer) {
        if P2PNetwork.isHost {
            let peers = [P2PNetwork.myPeer] + P2PNetwork.connectedPeers
            let players = peers.map { peer in getOrCreateGamePlayer(from: peer) }
            syncedPlayers.value = players
            delegate?.gameRoomPlayersDidChange(self)
        }
    }
}
