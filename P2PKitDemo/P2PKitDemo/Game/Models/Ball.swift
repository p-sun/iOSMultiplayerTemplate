//
//  GameViewModel.swift
//  P2PKitDemo
//
//  Created by Paige Sun on 5/16/24.
//

import UIKit
import P2PKit

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

struct BallVM: Codable {
    let position: CGPoint
    let ownerID: Peer.Identifier?
    
    static func create(from ball: Ball) -> BallVM {
        return BallVM(position: ball.position, ownerID: ball.ownerID)
    }
    
    func apply(on ball: Ball) {
        ball.position = position
        ball.ownerID = ownerID
    }
}

struct PhysicsVM: Codable {
    private let puckVMs: [BallVM]
    private let malletVMs: [BallVM]
    private let holeVMs: [BallVM]
    
    static var initial: PhysicsVM {
        return PhysicsVM(puckVMs: [], malletVMs: [], holeVMs: [])
    }
    
    static func create(from physics: AirHockeyPhysics) -> PhysicsVM {
        return PhysicsVM(
            puckVMs: physics.pucks.map{ BallVM.create(from: $0) },
            malletVMs: physics.mallets.map{ BallVM.create(from: $0) },
            holeVMs: physics.holes.map{ BallVM.create(from: $0) }
        )
    }
    
    func update(_ physics: AirHockeyPhysics) {
        physics.applyViewModels(ballVMs: puckVMs, kind: .puck)
        physics.applyViewModels(ballVMs: malletVMs, kind: .mallet)
        physics.applyViewModels(ballVMs: holeVMs, kind: .hole)
    }
}
