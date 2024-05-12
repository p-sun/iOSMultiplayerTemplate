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
        gameView.update(mallets: physics.mallets, puck: physics.puck, hole: physics.hole)
    }
    
    deinit {
        displayLink.invalidate()
    }
}
