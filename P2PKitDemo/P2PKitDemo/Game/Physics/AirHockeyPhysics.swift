//
//  AirHockeyPhysics.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/9/24.
//

import Foundation
import UIKit
import MultipeerConnectivity
import P2PKit

class Ball: Identifiable {
    enum Info {
        case puck, mallet, hole
    }
    
    let info: Info
    let radius: CGFloat
    let mass: CGFloat
    var velocity: CGPoint
    var position: CGPoint
    var isGrabbed = false
    var ownerID: MCPeerID?
    
    fileprivate init(info: Info, radius: CGFloat, mass: CGFloat, velocity: CGPoint, position: CGPoint, ownerID: MCPeerID?) {
        self.info = info
        self.radius = radius
        self.mass = mass
        self.velocity = velocity
        self.position = position
        self.ownerID = ownerID
    }
}

protocol AirHockeyPhysicsDelegate: AnyObject {
    func puckDidEnterHole(puck: Ball)
    func puckDidCollide(puck: Ball, ball: Ball)
    func puckDidCollideWithWall(puck: Ball)
}

class AirHockeyPhysics {
    weak var delegate: AirHockeyPhysicsDelegate? = nil
    
    private(set) var pucks = [Ball]()
    private(set) var mallets = [Ball]()
    private(set) var holes = [Ball]()
    private let boardSize: CGSize
    
    init(boardSize: CGSize) {
        self.boardSize = boardSize

        self.pucks = [
            Ball.createPuck(position: CGPoint(x: boardSize.width/2, y: boardSize.height/2)),
        ]

        self.holes = [Ball.createHole(boardSize: boardSize, awayFrom: [])]
        self.holes.append(Ball.createHole(boardSize: boardSize, awayFrom: self.holes.map {$0.position }))
    }
    
    //MARK: - Update
    
    // TODO: Use Ball View Model to update views. No need to touch 'physics'
    func updateMalletViews(for ballVMs: [BallVM]) {
        mallets = ballVMs.enumerated().map { (i, ballVM) in
            if i < mallets.count {
                mallets[i].position = ballVM.position
                return mallets[i]
            } else {
                let ball = Ball.createMallet(boardSize: boardSize, ownerID: P2PNetwork.myPeer.peerID)
                ball.position = ballVM.position
                return ball
            }
        }
    }
    
    func updateMallets(for players: [GamePlayer]) {
        mallets = players.map { player in
            if let existing = mallets.first(where: { $0.ownerID == player.peerID }) {
                return existing
            } else {
                return Ball.createMallet(boardSize: boardSize, ownerID: player.peerID)
            }
        }
    }
    
    func updateHoleViews(for ballVMs: [BallVM]) {
        holes = ballVMs.enumerated().map { (i, ballVM) in
            if i < holes.count {
                holes[i].position = ballVM.position
                return holes[i]
            } else {
                let hole = Ball.createHole(boardSize: boardSize, awayFrom: [])
                hole.position = ballVM.position
                return hole
            }
        }
    }
    
    func update(deltaTime: CGFloat) {
        updatePhysics(deltaTime: deltaTime)
        for hole in holes {
            for puck in pucks {
                puckIsInsideHole(puck: puck, hole: hole)
            }
        }
    }
    
    private func updatePhysics(deltaTime: CGFloat) {
        // MARK: Collisions updates velocity & position
        for puck in pucks {
            collideWithWalls(puck)
        }
        
        // Mallets with puck
        for i in mallets.indices {
            for puck in pucks {
                collide(mallets[i], puck)
            }
            collideWithWalls(mallets[i])
        }
        // Mallets with mallets
        if mallets.count > 1 {
            for i in 0..<mallets.count - 1 {
                for j in i+1..<mallets.count {
                    collide(mallets[i], mallets[j])
                }
            }
        }
        
        // MARK: Update position on free bodies
        for puck in pucks {
            updateFreeBodyPosition(puck, deltaTime: deltaTime)
        }
        for i in mallets.indices {
            updateFreeBodyPosition(mallets[i], deltaTime: deltaTime)
        }
        
        // MARK: Resolve overlapping
        // Mallets with puck
        for i in mallets.indices {
            for puck in pucks {
                resolveOverlap(grabbable: mallets[i], freebody: puck)
            }
            constrainWithinWalls(mallets[i])
        }
        // Mallets with mallets
        for puck in pucks {
            constrainWithinWalls(puck)
        }
    }
    
    private func updateFreeBodyPosition(_ b: Ball, deltaTime: CGFloat) {
        if !b.isGrabbed {
            b.position.x += b.velocity.x * deltaTime
            b.position.y += b.velocity.y * deltaTime
        }
    }
    
    //MARK: - Collisions
    
    private func collide(_ a: Ball, _ b: Ball) {
        guard !a.isGrabbed || !b.isGrabbed else {
            return
        }
        if a.isGrabbed {
            collideWithGrabbedBody(grabbed: a, freeBody: b)
        } else if b.isGrabbed {
            collideWithGrabbedBody(grabbed: b, freeBody: a)
        } else {
            collideBetweenFreeBodies(a, b)
        }
    }
    
    private func collideWithWalls(_ b: Ball) {
        let r = b.radius
        if b.position.x - r <= 0
            || b.position.x + r >= boardSize.width {
            b.velocity.x = -b.velocity.x
            
            if b.info == .puck { delegate?.puckDidCollideWithWall(puck: b) }
        }
        
        if b.position.y - r <= 0
            || b.position.y + r >= boardSize.height {
            b.velocity.y = -b.velocity.y
            if b.info == .puck { delegate?.puckDidCollideWithWall(puck: b) }
        }
    }
    
    private func puckIsInsideHole(puck: Ball, hole: Ball) {
        let dx = hole.position.x - puck.position.x
        let dy = hole.position.y - puck.position.y
        let distance = sqrt(dx * dx + dy * dy)
        
        if distance < hole.radius - puck.radius {
            delegate?.puckDidEnterHole(puck: puck)
            if let i = self.holes.firstIndex(where: {$0.id == hole.id }) {
                self.holes[i] = Ball.createHole(boardSize: boardSize, awayFrom: self.holes.map { $0.position })
            }
        }
    }
    
    private func collideWithGrabbedBody(grabbed a: Ball, freeBody b: Ball) {
        let dx = b.position.x - a.position.x
        let dy = b.position.y - a.position.y
        let distance = sqrt(dx * dx + dy * dy)
        let minDistance = a.radius + b.radius
        
        if distance < minDistance && distance != 0 {
            // Normal vector
            let nx = dx / distance
            let ny = dy / distance
            
            // Reposition to avoid overlap
            let overlap = minDistance - distance
            b.position.x += nx * overlap
            b.position.y += ny * overlap
            
            // Paddle's velocity in the direction of the normal
            // determines how fast the object is pushed
            let dpNormA = a.velocity.x * nx + a.velocity.y * ny
            let malletSpeed: CGFloat = (dpNormA * 6).clamp(min: 330, max: 1200)
            b.velocity.x = nx * malletSpeed
            b.velocity.y = ny * malletSpeed
            
            if b.info == .puck {
                delegate?.puckDidCollide(puck: b, ball: a)
            }
        }
    }
    
    private func collideBetweenFreeBodies(_ a: Ball, _ b: Ball) {
        let dx = b.position.x - a.position.x
        let dy = b.position.y - a.position.y
        let distance = sqrt(dx * dx + dy * dy)
        
        if distance <= (a.radius + b.radius) && distance != 0 {
            // Normal vector
            let nx = dx / distance
            let ny = dy / distance
            
            // Tangential vector
            let tx = -ny
            let ty = nx
            
            // Dot product tangent
            let dpTanA = a.velocity.x * tx + a.velocity.y * ty
            let dpTanB = b.velocity.x * tx + b.velocity.y * ty
            
            // Dot product normal
            let dpNormA = a.velocity.x * nx + a.velocity.y * ny
            let dpNormB = b.velocity.x * nx + b.velocity.y * ny
            
            // Conservation of momentum in 1D
            let mA = (dpNormA * (a.mass - b.mass) + 2 * b.mass * dpNormB) / (a.mass + b.mass)
            let mB = (dpNormB * (b.mass - a.mass) + 2 * a.mass * dpNormA) / (a.mass + b.mass)
            
            // Update velocities
            a.velocity.x = tx * dpTanA + nx * mA
            a.velocity.y = ty * dpTanA + ny * mA
            b.velocity.x = tx * dpTanB + nx * mB
            b.velocity.y = ty * dpTanB + ny * mB
            b.velocity = b.velocity.clampingMagnitude(max: 1200)
            
            // Resolve overlap
            let overlap = (a.radius + b.radius - distance + 0.01) / 2
            a.position.x -= overlap * nx
            a.position.y -= overlap * ny
            b.position.x += overlap * nx
            b.position.y += overlap * ny
            
            if b.info == .puck {
                delegate?.puckDidCollide(puck: b, ball: a)
            }
        }
    }
    
    //MARK: - Resolve Overlap
    
    private func resolveOverlap(grabbable a: Ball, freebody b: Ball) {
        let dx = b.position.x - a.position.x
        let dy = b.position.y - a.position.y
        let distance = sqrt(dx * dx + dy * dy)
        
        if distance < (a.radius + b.radius) && distance != 0 {
            // Normal vector
            let nx = dx / distance
            let ny = dy / distance
            
            // Resolve overlap
            let overlap: CGFloat
            if a.isGrabbed {
                // When the mallet is grabbed, only move the puck
                overlap = (a.radius + b.radius - distance)
            } else {
                // When the mallet is not grabbed, move mallet & puck
                overlap = (a.radius + b.radius - distance) / 2
                a.position.x -= overlap * nx
                a.position.y -= overlap * ny
            }
            b.position.x += overlap * nx
            b.position.y += overlap * ny
        }
    }
    
    private func constrainWithinWalls(_ b: Ball) {
        let r = b.radius
        if b.position.x - r <= 0 {
            b.position.x = r
        }
        if b.position.x + r >= boardSize.width {
            b.position.x = boardSize.width - r
        }
        if b.position.y - r <= 0 {
            b.position.y = r
        }
        if b.position.y + r >= boardSize.height {
            b.position.y = boardSize.height - r
        }
    }
}

//MARK: - Private Create Balls

extension Ball {
    fileprivate static func createPuck(position: CGPoint) -> Ball {
        return Ball(info: .puck,
                    radius: 30,
                    mass: 1,
                    velocity: CGPoint(x: -100, y: 300),
                    position:position,
                    ownerID: nil)
    }
    
    fileprivate static func createMallet(boardSize: CGSize, ownerID: MCPeerID) -> Ball {
        let radius: CGFloat = 40
        let position = CGPoint(
            x: .random(in: radius...boardSize.width-radius),
            y: .random(in: radius...boardSize.height-radius))
        return Ball(info: .mallet,
                    radius: radius,
                    mass: 10,
                    velocity: CGPoint.zero,
                    position: position,
                    ownerID: ownerID)
    }
    
    // Create a hole that doesn't overlap with existing holes
    fileprivate static func createHole(boardSize: CGSize, awayFrom positions: [CGPoint]) -> Ball {
        func isPositionFarEnoughAway(_ newPos: CGPoint) -> Bool {
            for position in positions {
                if (position - newPos).magnitude() < 200 {
                    return false
                }
            }
            return true
        }
        
        let radius: CGFloat = 46
        var newPos: CGPoint!
        repeat {
            newPos = CGPoint(
                x: .random(in: radius...boardSize.width-radius),
                y: .random(in: radius...boardSize.height-radius))
        } while !isPositionFarEnoughAway(newPos)
        
        return Ball(info: .hole,
                    radius: radius,
                    mass: 0,
                    velocity: CGPoint.zero,
                    position: newPos,
                    ownerID: nil)
    }
}
