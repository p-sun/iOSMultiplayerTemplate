//
//  AirHockeyController.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/9/24.
//

import Foundation
import QuartzCore

struct GameConfig {
    static let handleSize: CGFloat = 80
    static let ballRadius: CGFloat = 30
    static let ballInitialVelocity = CGVector(dx: -3, dy: 10)
}

class AirHockeyController {
    static var shared: AirHockeyController?
    
    private let physics: AirHockeyPhysics
    private let playAreaView: AirHockeyPlayAreaView
    private var displayLink: CADisplayLink!
    
    init(boardSize: CGSize, playAreaView: AirHockeyPlayAreaView) {
        self.physics = AirHockeyPhysics(boardSize: boardSize,
                                        ballRadius: GameConfig.ballRadius)
        self.playAreaView = playAreaView

        self.displayLink = CADisplayLink(target: self, selector: #selector(handleUpdate))
        displayLink.add(to: .main, forMode: .common)
    }
    
    @objc private func handleUpdate(displayLink: CADisplayLink) {
        physics.update()
        playAreaView.ball.center = physics.ball.position
    }
    
    deinit {
        displayLink.invalidate()
    }
}
