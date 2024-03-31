//
//  SendablePlayer.swift
//  MuPeerTest
//
//  Created by Paige Sun on 3/31/24.
//

import Foundation
import simd

struct SendablePlayer: PSSendable {
    var sender: String
    var timeSince1970: Double
    let playerTransform: simd_float4x4
    
    init(sender: String, playerTransform: simd_float4x4) {
        self.sender = sender
        self.timeSince1970 = Date().timeIntervalSince1970
        self.playerTransform = playerTransform
    }
}

extension simd_float4x4: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let row0 = try container.decode(simd_float4.self, forKey: .row0)
        let row1 = try container.decode(simd_float4.self, forKey: .row1)
        let row2 = try container.decode(simd_float4.self, forKey: .row2)
        let row3 = try container.decode(simd_float4.self, forKey: .row3)
        
        self.init(row0, row1, row2, row3)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(columns.0, forKey: .row0)
        try container.encode(columns.1, forKey: .row1)
        try container.encode(columns.2, forKey: .row2)
        try container.encode(columns.3, forKey: .row3)
    }
    
    private enum CodingKeys: String, CodingKey {
        case row0, row1, row2, row3
    }
}
