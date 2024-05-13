//
//  AirHockeyController.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/9/24.
//

import Foundation
import QuartzCore

class AirHockeyInstance {
    private var coordinator: AirHockeyCoordinator?
    
    var rootUIView: AirHockeyRootView {
        if let instance = coordinator {
            return instance.rootView
        }
        
        let gameView = AirHockeyGameView()
        let scoreView = AirHockeyScoreView()
        let rootView = AirHockeyRootView()
        gameView.didLayout = { [weak self, weak gameView, weak rootView] size in
            guard let self = self, let gameView = gameView , let rootView = rootView else { return }
            if coordinator == nil {
                coordinator = AirHockeyCoordinator(boardSize: size,
                                                   rootView: rootView,
                                                   gameView: gameView,
                                                   scoreView: scoreView)
            }
        }
        rootView.constrainSubviews(gameView: gameView, scoreView: scoreView)
        return rootView
    }
}

private class AirHockeyCoordinator {
    fileprivate let rootView: AirHockeyRootView
    private let gameView: AirHockeyGameView
    private let room = GameRoom()
    private let physics: AirHockeyPhysics
    private var displayLink: CADisplayLink!
    
    init(boardSize: CGSize, rootView: AirHockeyRootView, gameView: AirHockeyGameView, scoreView: AirHockeyScoreView) {
        self.rootView = rootView
        self.physics = AirHockeyPhysics(boardSize: boardSize)
        
        self.gameView = gameView
        gameView.gestureDelegate = self.physics
        
        room.playersDidChange = scoreView.playersDidChange
        
        self.displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink.add(to: .main, forMode: .common)
        
        self.physics.delegate = self
        
        for player in room.players {
            self.physics.addMallet(for: player.id)
        }
    }
    
    @objc private func update(displayLink: CADisplayLink) {
        physics.update(deltaTime: CGFloat(displayLink.duration))
        gameView.update(mallets: physics.mallets, puck: physics.puck, hole: physics.hole)
    }
    
    fileprivate func invalidate() {
        displayLink.invalidate()
    }
}

extension AirHockeyCoordinator: AirHockeyPhysicsDelegate {
    func puckDidEnterHole(puck: Ball) {
        if let ownerID = puck.ownerID {
            room.incrementScore(ownerID)
        }
        GameSounds.play(.ballEnteredHole)
    }
    
    func puckDidCollide(puck: Ball, ball: Ball) {
        if ball.info == .mallet, let ownerID = ball.ownerID {
            puck.ownerID = ownerID
        }
        GameSounds.play(.ballCollision)
    }
    
    func puckDidCollideWithWall() {
        GameSounds.play(.ballCollision)
    }
}
