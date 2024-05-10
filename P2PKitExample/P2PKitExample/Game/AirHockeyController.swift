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
    static let handleMassGrabbed: CGFloat = 20
    static let handleMassFreebody: CGFloat = 10

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
        playAreaView.setGestureDelegate(self)
        self.displayLink = CADisplayLink(target: self, selector: #selector(handleUpdate))
        displayLink.add(to: .main, forMode: .common)
    }
    
    @objc private func handleUpdate(displayLink: CADisplayLink) {
        physics.update(duration: CGFloat(displayLink.duration))
        
        playAreaView.ball.center = physics.ball.position
        playAreaView.handle.center = physics.handle.position
        playAreaView.handle.backgroundColor = physics.handle.isGrabbed ? .systemOrange : .systemIndigo
    }
    
    deinit {
        displayLink.invalidate()
    }
}

extension AirHockeyController: MultiGestureDetectorDelegate {
    func gestureDidStart(_ location: CGPoint) {
        physics.handle.position = location
        physics.handle.isGrabbed = true
        physics.handle.velocity = CGPoint.zero
    }
    
    func gestureDidMoveTo(_ location: CGPoint, velocity: CGPoint) {
        physics.handle.position = location
        physics.handle.isGrabbed = true
    }
    
    func gesturePanDidEnd(_ location: CGPoint, velocity: CGPoint) {
        physics.handle.position = location
        physics.handle.isGrabbed = false
        physics.handle.velocity = (velocity / 7).clampingMagnitude(max: 300)
    }
    
    func gesturePressDidEnd(_ location: CGPoint) {
        physics.handle.position = location
        physics.handle.isGrabbed = false
    }
}
