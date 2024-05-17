//
//  AirHockeyController.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/9/24.
//

import Foundation
import QuartzCore
import P2PKit
import MultipeerConnectivity

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
    private let syncedGameState: P2PSynced<PhysicsVM>
    private let malletDraggedEvents = P2PEventNetwork<MalletDragEvent>()
    
    init(boardSize: CGSize, rootView: AirHockeyRootView, gameView: AirHockeyGameView, scoreView: AirHockeyScoreView) {
        self.rootView = rootView
        self.scoreView = scoreView
        self.gameView = gameView
        self.physics = AirHockeyPhysics(boardSize: boardSize)
        
        // Networking
        self.syncedGameState = P2PSynced(name: "GameState", initial: PhysicsVM.initial, reliable: false)
        if P2PNetwork.isHost {
            malletDraggedEvents.onReceive(eventName: "MalletDrag") { [weak self] eventInfo, malletDragEvent, json, sender in
                guard let self = self else { return }
                let i = malletDragEvent.tag
                if i < physics.mallets.count {
                    physics.mallets[i].isGrabbed = malletDragEvent.isGrabbed
                    physics.mallets[i].position = malletDragEvent.position
                    if let velocity = malletDragEvent.velocity {
                        physics.mallets[i].velocity = velocity
                    }
                } else {
                    print("WARN: Tried to set mallet at index \(i), but we only have \(physics.mallets.count) mallets. Ignoring")
                }
            }
        } else {
            syncedGameState.didChange = { [weak self] gameState in
                guard let self = self else { return }
                gameState.update(physics)
            }
        }
        
        // Update Loop
        self.displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink.add(to: .main, forMode: .common)
        
        // Delegates
        gameView.gestureDelegate = self
        self.physics.delegate = self
        room.delegate = self
    }
    
    @objc private func update(displayLink: CADisplayLink) {
        frame += 1
        
        if P2PNetwork.isHost {
            physics.update(deltaTime: CGFloat(displayLink.duration))
            syncedGameState.value = PhysicsVM.create(from: physics)
        }

        // Render
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
        if P2PNetwork.isHost {
            self.physics.updateMallets(for: players)
        }
    }
}

extension AirHockeyCoordinator: MultiGestureDetectorDelegate {
    func gestureDidStart(_ position: CGPoint, tag: Int) {
        dragMallet(
            tag: tag,
            isGrabbed: true,
            position: position,
            velocity: CGPoint.zero)
    }
    
    func gestureDidMoveTo(_ position: CGPoint, velocity: CGPoint, tag: Int) {
        dragMallet(
            tag: tag,
            isGrabbed: true,
            position: position,
            velocity: (velocity / 7).clampingMagnitude(max: 300))
    }
    
    func gesturePanDidEnd(_ position: CGPoint, velocity: CGPoint, tag: Int) {
        dragMallet(
            tag: tag,
            isGrabbed: false,
            position: position,
            velocity: (velocity / 7).clampingMagnitude(max: 300))
    }
    
    func gesturePressDidEnd(_ position: CGPoint, tag: Int) {
        dragMallet(tag: tag,
                      isGrabbed: false,
                      position: position,
                      velocity: nil)
    }
    
    private func dragMallet(tag: Int, isGrabbed: Bool, position: CGPoint, velocity: CGPoint?) {
        // TODO: Don't allow multiple people to grab the same mallet
        if P2PNetwork.isHost {
            if tag < physics.mallets.count {
                let mallet = physics.mallets[tag]
                mallet.position = position
                mallet.isGrabbed = isGrabbed
                if let velocity {
                    mallet.velocity = velocity
                }
            }
        } else {
            malletDraggedEvents.send(
                eventName: "MalletDrag",
                payload: MalletDragEvent(tag: tag, isGrabbed: isGrabbed, position: position, velocity: velocity), senderID: "", reliable: false)
        }
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
