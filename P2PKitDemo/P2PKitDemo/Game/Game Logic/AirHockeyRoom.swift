//
//  AirHockeyRoom.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/12/24.
//

import Foundation
import UIKit

struct GamePlayer: Identifiable {
    let id: String
    let displayName: String
    let score: Int
    let color: UIColor
        
    private static var nextHue = 0.88//CGFloat.random(in: 0.2...0.9)
    
    static func create(displayName: String) -> GamePlayer {
        let color = UIColor.init(hue: nextHue, saturation: 0.8, brightness: 0.8, alpha: 1)
        nextHue = (nextHue + 0.37).truncatingRemainder(dividingBy: 1)
        return GamePlayer(id: UUID().uuidString, displayName: displayName, score: 0, color: color)
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
}

class GameRoom {
    var players = [GamePlayer]()
    var playersDidChange: (([GamePlayer]) -> Void)? = nil {
        didSet {
            playersDidChange?(players)
        }
    }
    
    init() {
        self.players = [GamePlayer.create(displayName: "Player 1"),
                        GamePlayer.create(displayName: "Player 2"),
                        GamePlayer.create(displayName: "Player 3"),]
    }
    
    func incrementScore(_ playerID: GamePlayer.ID) {
        if let index = players.firstIndex(where: { $0.id == playerID }) {
            players[index] = players[index].incrementScore()
            playersDidChange?(players)
        }
    }
}
