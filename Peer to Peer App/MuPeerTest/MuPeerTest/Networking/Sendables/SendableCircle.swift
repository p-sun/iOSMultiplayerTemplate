//
//  PeerInfo.swift
//  MuPeerTest
//
//  Created by Paige Sun on 3/30/24.
//

import Foundation

struct SendableCircle: PSSendable {
    var point: CGPoint
    let sender: String
    let timeSince1970: Double
    
    init(sender: String, point: CGPoint) {
        self.sender = sender
        self.timeSince1970 = Date().timeIntervalSince1970
        self.point = point
    }
}
