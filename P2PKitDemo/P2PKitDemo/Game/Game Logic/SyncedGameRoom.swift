//
//  GameRoom.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/12/24.
//

import Foundation
import UIKit
import P2PKit
import MultipeerConnectivity

protocol GameRoomPlayerDelegate: AnyObject {
    func gameRoomPlayersDidChange(_ gameRoom: SyncedGameRoom)
}

class SyncedGameRoom {
    weak var delegate: GameRoomPlayerDelegate? {
        didSet {
            delegate?.gameRoomPlayersDidChange(self)
        }
    }
    
    // All players including self
    var players: [Player] {
        return syncedRoom.value.players
    }
    
    private let syncedRoom: P2PSynced<GameRoom>
    
    init() {
        syncedRoom = P2PSynced<GameRoom>(
            name: runGameLocally ? UUID().uuidString : "SyncedRoom",
            initial: runGameLocally ? GameRoom.createMock() : GameRoom.createEmpty(),
            reliable: true)
        syncedRoom.onReceiveSync = { [weak self] roomVM in
            guard let self = self else { return }
            delegate?.gameRoomPlayersDidChange(self)
        }
        
        P2PNetwork.addPeerDelegate(self)
        P2PNetwork.start()
        
        delegate?.gameRoomPlayersDidChange(self)
    }
}

// MARK: - Host Only

extension SyncedGameRoom {
    func incrementScore(_ playerID: Peer.Identifier) {
        guard P2PNetwork.isHost || runGameLocally else { return }
        
        var playerInfos = syncedRoom.value.playerInfos
        if let oldPlayer = playerInfos[playerID] {
            playerInfos[playerID] = oldPlayer.incrementScore()
            let connectedIDs: [Peer.Identifier]
            if runGameLocally {
                connectedIDs = syncedRoom.value.connectedIds
            } else {
                connectedIDs = [P2PNetwork.myPeer.id] 
                + P2PNetwork.connectedPeers.map { $0.id }
            }
            syncedRoom.value = GameRoom(
                playerInfos: playerInfos,
                connectedIDs: connectedIDs,
                nextPlayerHue: syncedRoom.value.nextPlayerHue
            )
            delegate?.gameRoomPlayersDidChange(self)
        }
    }
}

extension SyncedGameRoom: P2PNetworkPeerDelegate {
    func p2pNetwork(didUpdate peer: Peer) {
        guard P2PNetwork.isHost else { return }
        
        var playerInfos = syncedRoom.value.playerInfos
        var nextHue = syncedRoom.value.nextPlayerHue
        
        if playerInfos[peer.id] == nil {
            let player = Player(
                playerID: peer.id,
                score: 0,
                color: UIColor(hue: nextHue, saturation: 0.8, brightness: 0.8, alpha: 1))
            playerInfos[peer.id] = player
            nextHue = (nextHue + 0.37).truncatingRemainder(dividingBy: 1)
        }
        
        let connectedIDs = [P2PNetwork.myPeer.id] + P2PNetwork.connectedPeers.map { $0.id }
        syncedRoom.value = GameRoom(
            playerInfos: playerInfos,
            connectedIDs: connectedIDs,
            nextPlayerHue: nextHue
        )
        delegate?.gameRoomPlayersDidChange(self)
    }
}
