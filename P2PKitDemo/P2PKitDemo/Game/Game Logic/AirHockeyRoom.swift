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

struct GamePlayer: Identifiable {
    let id: String
    let displayName: String
    let score: Int
    let color: UIColor
    
    private static var nextHue = 0.83//CGFloat.random(in: 0.2...0.9)
    
    static func create(id: String = UUID().uuidString, displayName: String) -> GamePlayer {
        let color = UIColor(hue: nextHue, saturation: 0.8, brightness: 0.8, alpha: 1)
        nextHue = (nextHue + 0.37).truncatingRemainder(dividingBy: 1)
        return GamePlayer(id: id, displayName: displayName, score: 0, color: color)
    }
    
    private init(id: String, displayName: String, score: Int, color: UIColor) {
        self.id = id
        self.displayName = displayName
        self.score = score
        self.color = color
    }
    
    fileprivate func incrementScore() -> GamePlayer {
        return GamePlayer(id: id, displayName: displayName, score: score + 1, color: color)
    }
    
    fileprivate func updateFromPeer(_ peer: Peer) -> GamePlayer {
        return GamePlayer(id: id, displayName: peer.displayName, score: score, color: color)
    }
    
    fileprivate func withDisplayName(_ displayName: String) -> GamePlayer {
        return GamePlayer(id: id, displayName: displayName, score: score, color: color)
    }
}

private struct PlayerInfo {
    let score: Int
    let color: UIColor
}

protocol GameRoomPlayerDelegate: AnyObject {
    func playersDidChange(_ players: [GamePlayer])
}

class GameRoom {
    weak var delegate: GameRoomPlayerDelegate? {
        didSet {
            delegate?.playersDidChange(players)
        }
    }
    
    private var infos = [String: PlayerInfo]()
    
    var players = [GamePlayer]() {
        didSet {
            delegate?.playersDidChange(players)
        }
    }
    
    init() {
        P2PNetwork.addPeerDelegate(self)
        P2PNetwork.start()
        
        self.players = [GamePlayer.create(displayName: "Player 1"),
                        GamePlayer.create(displayName: "Player 2"),
                        GamePlayer.create(displayName: "Player 3")]
    }
    
    func incrementScore(_ playerID: GamePlayer.ID) {
        if let index = players.firstIndex(where: { $0.id == playerID }) {
            players[index] = players[index].incrementScore()
        }
    }
}

extension GameRoom: P2PNetworkPeerDelegate {
    func p2pNetwork(didUpdate peer: Peer) {
//        let otherPlayers = P2PNetwork.allPeers.map { gamePlayer(for: $0) }
//        players = [gamePlayer(for: P2PNetwork.myPeer)] + otherPlayers
    }
    
    private func gamePlayer(for peer: Peer) -> GamePlayer {
        if let existingPlayer = players.first(where: { $0.id == "\(peer.id)" }) {
            return existingPlayer.withDisplayName(peer.displayName)
        }
        return GamePlayer.create(id: "\(peer.id)", displayName: peer.displayName)
    }
}
