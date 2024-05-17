//
//  GameViewModel.swift
//  P2PKitDemo
//
//  Created by Paige Sun on 5/16/24.
//

import UIKit

struct BallVM: Codable {
    let position: CGPoint
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
            puckVMs: physics.pucks.map{BallVM(position: $0.position)},
            malletVMs: physics.mallets.map{BallVM(position: $0.position)},
            holeVMs: physics.holes.map{BallVM(position: $0.position )}
        )
    }
    
    func update(_ physics: AirHockeyPhysics) {
        physics.pucks[0].position = puckVMs[0].position
        physics.updateMalletViews(for: malletVMs)
        physics.updateHoleViews(for: holeVMs)
    }
}
