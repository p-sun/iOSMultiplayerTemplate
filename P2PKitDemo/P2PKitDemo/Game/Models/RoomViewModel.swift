//
//  RoomViewModel.swift
//  P2PKitDemo
//
//  Created by Paige Sun on 5/16/24.
//

import Foundation
import UIKit

struct RoomVM: Codable {
    struct PlayerVM: Codable {
        let playerID: String
        let color: ColorVM
    }
    
    let players: [PlayerVM]
}

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
