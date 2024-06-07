//
//  AirHockeyController.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/9/24.
//

import Foundation
import QuartzCore
import P2PKit

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
                coordinator = AirHockeyCoordinator(
                    boardSize: size,
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
    // MARK: Views
    fileprivate let rootView: AirHockeyRootView
    private let gameView: AirHockeyGameView
    private weak var scoreView: AirHockeyScoreView?
    
    // MARK: Networked States
    private let malletDraggedEvents = P2PEventService<MalletDragEvent>("MalletDrag")
    private let syncedRoom: SyncedGameRoom
    private let syncedPhysics: P2PSynced<PhysicsVM>
    
    // MARK: Per-frame Updates
    private let physics: AirHockeyPhysics
    private var displayLink: CADisplayLink!
    private var lastCollisonSounds = [Ball.ID: (position: CGPoint, frame: Int)]()
    private var frame = 0
    
    init(boardSize: CGSize, rootView: AirHockeyRootView, gameView: AirHockeyGameView, scoreView: AirHockeyScoreView) {
        self.rootView = rootView
        self.scoreView = scoreView
        self.gameView = gameView
        self.syncedRoom = SyncedGameRoom()
        self.physics = AirHockeyPhysics(boardSize: boardSize)
        
        // Networking
        self.syncedPhysics = P2PSynced(name: "SyncedPhysics", initial: PhysicsVM.initial, writeAccess: .hostOnly)
        self.syncedPhysics.onReceiveSync = { [weak self] (physicsVM: PhysicsVM) in
            guard let self = self else { return }
            if !self.syncedRoom.isHost {
                physics.apply(physicsVM: physicsVM)
            }
        }
        
        self.syncedRoom.onRoomSync = { [weak self] gameRoom in
            guard let self = self else { return }
            let players = gameRoom.players
            scoreView.playersDidChange(players)
            if self.syncedRoom.isHost {
                self.physics.updateMallets(for: players)
            }
        }
        
        self.malletDraggedEvents.onReceive { [weak self] eventInfo, malletDragEvent, json, sender in
            guard let self = self, syncedRoom.isHost else { return }
            physics.applyMalletDragEvent(malletDragEvent: malletDragEvent)
        }
        
        // Update Loop
        self.displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink.add(to: .main, forMode: .common)
        
        // Delegates
        gameView.gestureDelegate = self
        self.physics.delegate = self
    }
    
    @objc private func update(displayLink: CADisplayLink) {
        frame += 1
        
        if syncedRoom.isHost {
            physics.update(deltaTime: CGFloat(displayLink.duration))
            syncedPhysics.value = physics.physicsVM()
        }
        // Render
        gameView.update(physics.gameViewVM(), players: syncedRoom.players)
    }
    
    fileprivate func invalidate() {
        displayLink.invalidate()
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
        if syncedRoom.isHost {
            physics.dragMallet(tag: tag, isGrabbed: isGrabbed, position: position, velocity: velocity)
        } else {
            malletDraggedEvents.send(payload: MalletDragEvent(tag: tag, isGrabbed: isGrabbed, position: position, velocity: velocity), senderID: "", reliable: false)
        }
    }
}

extension AirHockeyCoordinator: AirHockeyPhysicsDelegate {
    func puckDidEnterHole(puck: Ball) {
        GameSounds.play(.ballEnteredHole)
        if let ownerID = puck.ownerID {
            syncedRoom.incrementScore(ownerID)
        }
    }
    
    func puckDidCollide(puck: Ball, ball: Ball) {
        if ball.kind == .mallet, let ownerID = ball.ownerID {
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
