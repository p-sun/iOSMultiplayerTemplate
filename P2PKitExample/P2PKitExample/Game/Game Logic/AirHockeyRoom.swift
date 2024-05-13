//
//  AirHockeyRoom.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/12/24.
//

import Foundation

struct GamePlayer {
    let id: String
    let score: Int
}

class GameRoom {
    var players = [GamePlayer]()
    var playersDidChange: (([GamePlayer]) -> Void)? = nil {
        didSet {
            playersDidChange?(players)
        }
    }
    
    init() {
        print("Init Game Room")
        self.players = [GamePlayer(id: "Player 1", score: 0),
                        GamePlayer(id: "Player 2", score: 0),
                        GamePlayer(id: "Player 3", score: 0)]
    }
    
    func incrementScore(_ player: GamePlayer) {
        let index = players.firstIndex { $0.id == player.id }
        if let index = index {
            players[index] = GamePlayer(id: player.id, score: players[index].score + 1)
            playersDidChange?(players)
        }
    }
}
