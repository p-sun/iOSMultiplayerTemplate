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
    static let handleMass: CGFloat = 8

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
        self.physics = AirHockeyPhysics(boardSize: boardSize,
                                        ballRadius: GameConfig.ballRadius,
                                        handleRadius: GameConfig.handleRadius)
        self.playAreaView = playAreaView
        playAreaView.delegate = self
        self.displayLink = CADisplayLink(target: self, selector: #selector(handleUpdate))
        displayLink.add(to: .main, forMode: .common)
    }
    
    @objc private func handleUpdate(displayLink: CADisplayLink) {
        physics.update(duration: CGFloat(displayLink.duration))
        playAreaView.ball.center = physics.ball.position
        playAreaView.handle.center = physics.handle.position
    }
    
    deinit {
        displayLink.invalidate()
    }
}

extension AirHockeyController: AirHockeyPlayAreaViewDelegate {
    func airHockeyViewDidMoveHandle(_ location: CGPoint, velocity: CGPoint) {
        physics.handle.position = location
        physics.handle.velocity = (velocity / 5).capMagnitudeTo(max: 200)
    }
}
