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
    private let playAreaView: AirHockeyGameView
    private var displayLink: CADisplayLink!
    
    init(boardSize: CGSize, playAreaView: AirHockeyGameView) {
        self.physics = AirHockeyPhysics(boardSize: boardSize)
        self.playAreaView = playAreaView
        playAreaView.setGestureDelegate(self.physics)
        self.displayLink = CADisplayLink(target: self, selector: #selector(malletUpdate))
        displayLink.add(to: .main, forMode: .common)
    }
    
    @objc private func malletUpdate(displayLink: CADisplayLink) {
        physics.update(deltaTime: CGFloat(displayLink.duration))
        
        playAreaView.puckView.center = physics.puck.position
        playAreaView.malletView.center = physics.mallet.position
        playAreaView.malletView.backgroundColor = physics.mallet.isGrabbed ? .systemOrange : .systemIndigo
    }
    
    deinit {
        displayLink.invalidate()
    }
}
