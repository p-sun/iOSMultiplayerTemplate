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
    let owner: String
    var point: CGPoint
    let timeSince1970: Double
    
    init(owner: String, point: CGPoint) {
        self.owner = owner
        self.point = point
        self.timeSince1970 = Date().timeIntervalSince1970
    }
}
