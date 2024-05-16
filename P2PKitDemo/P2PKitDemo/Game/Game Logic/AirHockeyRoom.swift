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

private struct PlayerInfo {
    private static var nextHue = 0.83//CGFloat.random(in: 0.2...0.9)
    
    let score: Int
    let color: UIColor
    
    static func create() -> PlayerInfo {
        let color = UIColor(hue: nextHue, saturation: 0.8, brightness: 0.8, alpha: 1)
        nextHue = (nextHue + 0.37).truncatingRemainder(dividingBy: 1)
        return PlayerInfo(score: 0, color: color)
    }
}

struct GamePlayer {
    let peerID: MCPeerID
    var displayName: String {
        return peerID.displayName
    }
    let score: Int
    let color: UIColor
    
    fileprivate init(peerID: MCPeerID, score: Int, color: UIColor) {
        self.peerID = peerID
        self.score = score
        self.color = color
    }
}

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
    var players: [GamePlayer] {
        return peersIDs.compactMap {
            let info = getPlayerInfo($0)
            return GamePlayer(peerID: $0, score: info.score, color: info.color)
        }
    }
     
    private var playerInfos = [MCPeerID: PlayerInfo]()
    private var peersIDs = [MCPeerID]()
    
    init() {
        P2PNetwork.addPeerDelegate(self)
        P2PNetwork.start()
        
        self.peersIDs = [
            MCPeerID(displayName: "Player 1"),
            MCPeerID(displayName: "Player 2"),
            MCPeerID(displayName: "Player 3")]
    }
    
    func incrementScore(_ peerID: MCPeerID) {
        let info = getPlayerInfo(peerID)
        playerInfos[peerID] = PlayerInfo(score: info.score + 1, color: info.color)
        delegate?.gameRoomPlayersDidChange(self)
    }
    
    private func getPlayerInfo(_ peerID: MCPeerID) -> PlayerInfo {
        if let info = playerInfos[peerID] {
            return info
        } else {
            let info = PlayerInfo.create()
            playerInfos[peerID] = info
            return info
        }
    }
}

extension GameRoom: P2PNetworkPeerDelegate {
    func p2pNetwork(didUpdate peer: Peer) {
        peersIDs = [P2PNetwork.myPeer.peerID] + P2PNetwork.connectedPeers.map { $0.peerID }
        delegate?.gameRoomPlayersDidChange(self)
    }
}
