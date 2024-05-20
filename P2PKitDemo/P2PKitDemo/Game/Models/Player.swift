//
//  RoomViewModel.swift
//  P2PKitDemo
//
//  Created by Paige Sun on 5/16/24.
//

import Foundation
import UIKit
import P2PKit

struct Player: Codable {
    let playerID: Peer.Identifier
    let score: Int
    var color: UIColor {
        _color.color
    }
    private let _color: ColorVM
    
    init(playerID: String, score: Int, color: UIColor) {
        self.score = score
        self.playerID = playerID
        self._color = ColorVM(color)
    }
    
    func incrementScore() -> Player {
        return Player(playerID: playerID, score: score + 1, color: color)
    }
}

struct RoomServerVM: Codable {
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
    
    static func createEmpty() -> RoomServerVM {
        RoomServerVM(playerInfos: [:], connectedIDs: [], nextPlayerHue: 0.83)
    }
    
    static func createMock() -> RoomServerVM {
        RoomServerVM(
            playerInfos: ["Player 1": Player(playerID: "Player 1", score: 0, color: #colorLiteral(red: 0.5386788845, green: 0.3363381028, blue: 0.9497646689, alpha: 1)),
                          "Player 2": Player(playerID: "Player 2", score: 0, color: #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)),
                          "Player 3": Player(playerID: "Player 3", score: 0, color: #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1))],
            connectedIDs: ["Player 1", "Player 2", "Player 3"],
            nextPlayerHue: 0.83)
    }
}

// Codable UIColor
struct ColorVM: Codable {
    let color: UIColor
    
    init(_ color: UIColor) {
        self.color = color
    }
    
    enum CodingKeys: String, CodingKey {
        case red, green, blue, alpha
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            throw EncodingError.invalidValue(color, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Invalid UIColor, cannot be encoded"))
        }
        
        try container.encode(red, forKey: .red)
        try container.encode(green, forKey: .green)
        try container.encode(blue, forKey: .blue)
        try container.encode(alpha, forKey: .alpha)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let red = try container.decode(CGFloat.self, forKey: .red)
        let green = try container.decode(CGFloat.self, forKey: .green)
        let blue = try container.decode(CGFloat.self, forKey: .blue)
        let alpha = try container.decode(CGFloat.self, forKey: .alpha)
        
        self.color = UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
