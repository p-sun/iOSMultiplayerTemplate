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

class SyncedGameRoom {
    // All players including self
    var players: [Player] {
        return syncedRoom.value.players
    }
    
    var onRoomSync: (() -> Void)? {
        didSet {
            onRoomSync?()
        }
    }
    
    private var syncedRoom: P2PSynced<GameRoom>
    
    init() {
        syncedRoom = P2PSynced<GameRoom>(
            name: "SyncedRoom",
            initial: runGameLocally ? GameRoom.createMock() : GameRoom.createEmpty(),
            reliable: true)
        syncedRoom.onReceiveSync = { [weak self] roomVM in
            guard let self = self else { return }
            onRoomSync?()
        }
        
        P2PNetwork.addPeerDelegate(self)
        P2PNetwork.start()
        
        onRoomSync?()
    }
}

// MARK: - Host Only

extension SyncedGameRoom {
    func incrementScore(_ playerID: Peer.Identifier) {
        guard P2PNetwork.isHost || runGameLocally else { return }
        
        var playerInfos = syncedRoom.value.playerInfos
        if let oldPlayer = playerInfos[playerID] {
            playerInfos[playerID] = oldPlayer.incrementScore()
            syncedRoom.value = GameRoom(
                playerInfos: playerInfos,
                connectedIDs: getConnectedIDs(),
                nextPlayerHue: syncedRoom.value.nextPlayerHue
            )
            onRoomSync?()
        }
    }
}

extension SyncedGameRoom: P2PNetworkPeerDelegate {
    func p2pNetwork(didUpdate peer: Peer) {
        guard P2PNetwork.isHost else { return }
        
        var playerInfos = syncedRoom.value.playerInfos
        var nextHue = syncedRoom.value.nextPlayerHue
        
        let connectedIDs = getConnectedIDs()
        for id in connectedIDs {
            if playerInfos[id] == nil {
                let player = Player(
                    playerID: id,
                    score: 0,
                    color: UIColor(hue: nextHue, saturation: 0.8, brightness: 0.8, alpha: 1))
                playerInfos[id] = player
                nextHue = (nextHue + 0.37).truncatingRemainder(dividingBy: 1)
            }
        }
        
        syncedRoom.value = GameRoom(
            playerInfos: playerInfos,
            connectedIDs: connectedIDs,
            nextPlayerHue: nextHue
        )
        onRoomSync?()
    }
    
    private func getConnectedIDs() -> [Peer.Identifier] {
            return [P2PNetwork.myPeer.id]
            + P2PNetwork.connectedPeers.map { $0.id }
    }
}
