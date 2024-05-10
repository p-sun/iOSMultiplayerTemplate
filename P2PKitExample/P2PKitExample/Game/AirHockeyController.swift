//
//  AirHockeyController.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/9/24.
//

import Foundation
import QuartzCore

struct GameConfig {
    static let handleRadius: CGFloat = 40
    static let handleMass: CGFloat = 10
    
    static let ballRadius: CGFloat = 30
    static let ballMass: CGFloat = 1
    static let ballInitialVelocity = CGPoint(x: -100, y: 300)
}

class AirHockeyController {
    static var shared: AirHockeyController?
    
    private let physics: AirHockeyPhysics
    private let playAreaView: AirHockeyPlayAreaView
    private var displayLink: CADisplayLink!
    
    init(boardSize: CGSize, playAreaView: AirHockeyPlayAreaView) {
        self.physics = AirHockeyPhysics(boardSize: boardSize)
        self.playAreaView = playAreaView
        playAreaView.setGestureDelegate(self.physics)
        self.displayLink = CADisplayLink(target: self, selector: #selector(handleUpdate))
        displayLink.add(to: .main, forMode: .common)
    }
    
    @objc private func handleUpdate(displayLink: CADisplayLink) {
        physics.update(duration: CGFloat(displayLink.duration))
        playAreaView.ball.center = physics.puck.position
        playAreaView.handle.center = physics.pusher.position
        playAreaView.handle.backgroundColor = physics.pusher.isGrabbed ? .systemOrange : .systemIndigo
    }
    
    deinit {
        displayLink.invalidate()
    }
}
