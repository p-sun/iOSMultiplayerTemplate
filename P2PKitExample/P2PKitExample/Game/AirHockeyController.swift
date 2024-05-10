//
//  AirHockeyController.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/9/24.
//

import Foundation
import QuartzCore

struct GameConfig {
    static let malletRadius: CGFloat = 40
    static let malletMass: CGFloat = 10
    
    static let ballRadius: CGFloat = 30
    static let ballMass: CGFloat = 1
    static let ballInitialVelocity = CGPoint(x: -100, y: 300)
}

class AirHockeyController {
    static var shared: AirHockeyController?
    
    private let physics: AirHockeyPhysics
    private let gameView: AirHockeyGameView
    private var displayLink: CADisplayLink!
    
    init(boardSize: CGSize, playAreaView: AirHockeyGameView) {
        self.physics = AirHockeyPhysics(boardSize: boardSize)
        self.gameView = playAreaView
        playAreaView.gestureDelegate = self.physics
        self.displayLink = CADisplayLink(target: self, selector: #selector(malletUpdate))
        displayLink.add(to: .main, forMode: .common)
    }
    
    @objc private func malletUpdate(displayLink: CADisplayLink) {
        physics.update(deltaTime: CGFloat(displayLink.duration))
        
        gameView.holeView.center = physics.hole.position
        gameView.puckView.center = physics.puck.position
        gameView.updateMallets(physics.mallets)
    }
    
    deinit {
        displayLink.invalidate()
    }
}
