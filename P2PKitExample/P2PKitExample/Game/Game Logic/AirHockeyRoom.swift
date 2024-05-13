//
//  AirHockeyRoom.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/12/24.
//

import Foundation

struct GamePlayer: Identifiable {
    let id: String
    let displayName: String
    let score: Int
    
    fileprivate init(id: String, displayName: String, score: Int) {
        self.id = id
        self.displayName = displayName
        self.score = score
    }
    
    fileprivate func incrementingScore() -> GamePlayer {
        return GamePlayer(id: id, displayName: displayName, score: score + 1)
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
        self.players = [GamePlayer(id: UUID().uuidString, displayName: "Player 1", score: 0),
                        GamePlayer(id: UUID().uuidString, displayName: "Player 2", score: 0),
                        GamePlayer(id: UUID().uuidString, displayName: "Player 3", score: 0)]
    }
    
    func incrementScore(_ playerID: GamePlayer.ID) {
        if let index = players.firstIndex(where: { $0.id == playerID }) {
            players[index] = players[index].incrementingScore()
            playersDidChange?(players)
        }
    }
}
