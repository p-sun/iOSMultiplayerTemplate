//
//  GameViewModel.swift
//  P2PKitDemo
//
//  Created by Paige Sun on 5/16/24.
//

import UIKit
import P2PKit

// MARK: - Model

class Ball: Identifiable {
    enum Kind {
        case puck, mallet, hole
    }
    
    let kind: Kind
    let radius: CGFloat
    let mass: CGFloat
    var velocity: CGPoint
    var position: CGPoint
    var isGrabbed = false
    var ownerID: Peer.Identifier?
    
    init(info: Kind, radius: CGFloat, mass: CGFloat, velocity: CGPoint, position: CGPoint, ownerID: Peer.Identifier?) {
        self.kind = info
        self.radius = radius
        self.mass = mass
        self.velocity = velocity
        self.position = position
        self.ownerID = ownerID
    }
}

// MARK: - View Models

struct BallVM: Codable {
    let position: CGPoint
    let velocity: CGPoint
    let ownerID: Peer.Identifier?
    let isGrabbed: Bool
    
    static func create(from ball: Ball) -> BallVM {
        return BallVM(position: ball.position, velocity: ball.velocity, ownerID: ball.ownerID, isGrabbed: ball.isGrabbed)
    }
    
    func apply(on ball: Ball) {
        ball.position = position
        ball.velocity = velocity
        ball.ownerID = ownerID
        ball.isGrabbed = isGrabbed
    }
}

struct PhysicsVM: Codable {
    let puckVMs: [BallVM]
    let malletVMs: [BallVM]
    let holeVMs: [BallVM]
    
    static var initial: PhysicsVM {
        return PhysicsVM(puckVMs: [], malletVMs: [], holeVMs: [])
    }
}
