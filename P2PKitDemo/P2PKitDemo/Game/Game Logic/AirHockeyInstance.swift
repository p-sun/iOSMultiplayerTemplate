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
    private weak var scoreView: AirHockeyScoreView?
    private let room = GameRoom()
    private let physics: AirHockeyPhysics
    private var displayLink: CADisplayLink!
    private var lastCollisonSounds = [Ball.ID: (position: CGPoint, frame: Int)]()
    private var frame = 0
    
    init(boardSize: CGSize, rootView: AirHockeyRootView, gameView: AirHockeyGameView, scoreView: AirHockeyScoreView) {
        self.rootView = rootView
        self.scoreView = scoreView
        self.physics = AirHockeyPhysics(boardSize: boardSize)
        
        self.gameView = gameView
        gameView.gestureDelegate = self.physics
        
        self.displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink.add(to: .main, forMode: .common)
        
        self.physics.delegate = self
        room.delegate = self
    }
    
    @objc private func update(displayLink: CADisplayLink) {
        frame += 1
        physics.update(deltaTime: CGFloat(displayLink.duration))
        gameView.update(mallets: physics.mallets, pucks: physics.pucks, holes: physics.holes, players: room.players)
    }
    
    fileprivate func invalidate() {
        displayLink.invalidate()
    }
}

extension AirHockeyCoordinator: GameRoomPlayerDelegate {
    func gameRoomPlayersDidChange(_ gameRoom: GameRoom) {
        let players = gameRoom.players
        scoreView?.playersDidChange(players)
        self.physics.updateMallets(for: players)
    }
}

extension AirHockeyCoordinator: AirHockeyPhysicsDelegate {
    func puckDidEnterHole(puck: Ball) {
        GameSounds.play(.ballEnteredHole)
        if let ownerID = puck.ownerID {
            room.incrementScore(ownerID)
        }
    }
    
    func puckDidCollide(puck: Ball, ball: Ball) {
        if ball.info == .mallet, let ownerID = ball.ownerID {
            puck.ownerID = ownerID
        }
        playCollisonSound(for: puck)
    }
    
    func puckDidCollideWithWall(puck: Ball) {
        playCollisonSound(for: puck)
    }
    
    private func playCollisonSound(for ball: Ball) {
        if let lastCollision = lastCollisonSounds[ball.id] {
            if (ball.position - lastCollision.position).magnitude() > 50
                && (frame - lastCollision.frame) > 2 {
                GameSounds.play(.ballCollision)
                lastCollisonSounds[ball.id] = (position: ball.position, frame: frame)
            }
        } else {
            GameSounds.play(.ballCollision)
            lastCollisonSounds[ball.id] = (position: ball.position, frame: frame)
        }
    }
}
