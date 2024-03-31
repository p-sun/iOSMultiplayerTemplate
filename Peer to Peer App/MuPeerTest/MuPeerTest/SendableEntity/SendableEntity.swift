//
//  SendablePeer.swift
//  MuPeerTest
//
//  Created by Paige Sun on 3/30/24.
//

import Foundation

struct SendablePeer: Codable {
    var peerName: String
    var count: Int
}

struct SendableEntity: Codable {
    var peerName: String
    var point: CGPoint
}

struct DotPoint: Codable {
    let x : Double
    let y : Double
    
    init(_ point:CGPoint) {
        x = Double(point.x)
        y = Double(point.y)
    }
}

//extension CGPoint: Codable {
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(x, forKey: .x)
//        try container.encode(y, forKey: .y)
//    }
//    
//    public init(from decoder: Decoder) throws {
//        let values = try decoder.container(keyedBy: CodingKeys.self)
//        let x = try values.decode(CGFloat.self, forKey: .x)
//        let y = try values.decode(CGFloat.self, forKey: .y)
//        self.init(x: x, y: y)
//    }
//    
//    private enum CodingKeys: String, CodingKey {
//        case x
//        case y
//    }
//}
