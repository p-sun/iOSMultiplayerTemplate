//
//  AirHockeyController.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/9/24.
//

import Foundation
import QuartzCore

class AirHockeyController {
    static var shared: AirHockeyController?
    
    private let room = GameRoom()
    private let physics: AirHockeyPhysics
    private let gameView: AirHockeyGameView
    private var displayLink: CADisplayLink!
    
    init(boardSize: CGSize, gameView: AirHockeyGameView, scoreView: AirHockeyRootUIView) {
        self.physics = AirHockeyPhysics(boardSize: boardSize)
        self.gameView = gameView
        gameView.gestureDelegate = self.physics
        room.playersDidChange = scoreView.playersDidChange
        
        self.displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink.add(to: .main, forMode: .common)
    }
    
    @objc private func update(displayLink: CADisplayLink) {
        physics.update(deltaTime: CGFloat(displayLink.duration))
        gameView.update(mallets: physics.mallets, puck: physics.puck, hole: physics.hole)
    }
    
    deinit {
        displayLink.invalidate()
    }
}
