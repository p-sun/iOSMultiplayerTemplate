//
//  AirHockeyPhysics.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/9/24.
//

import Foundation
import UIKit

struct Ball {
    let radius: CGFloat
    let mass: CGFloat
    var velocity: CGPoint
    var position: CGPoint
    var isGrabbed: Bool = false
    
    init(radius: CGFloat, mass: CGFloat, velocity: CGPoint, position: CGPoint) {
        self.radius = radius
        self.mass = mass
        self.velocity = velocity
        self.position = position
    }
}

class AirHockeyPhysics {
    private(set) var puck: Ball
    private(set) var mallet: Ball
    
    private let boardSize: CGSize
    
    init(boardSize: CGSize) {
        self.puck = Ball(radius: GameConfig.ballRadius,
                         mass: GameConfig.ballMass,
                         velocity: GameConfig.ballInitialVelocity,
                         position: CGPoint(x: boardSize.width/2,
                                           y: boardSize.height/2))
        self.mallet = Ball(radius: GameConfig.malletRadius,
                           mass: GameConfig.malletMass,
                           velocity: CGPoint.zero,
                           position: CGPoint(x: boardSize.width/2,
                                             y: boardSize.height - 80))
        self.boardSize = boardSize
    }
    
    //MARK: - Update
    
    func update(deltaTime: CGFloat) {
        // MARK: Collisions updates velocity & position
        if mallet.isGrabbed {
            collideWithGrabbedBody(grabbed: &mallet, freeBody: &puck)
        } else {
            collideBetweenFreeBodies(&mallet, &puck)
        }
        collideWithWalls(&puck)
        collideWithWalls(&mallet)
        
        // MARK: Update position on free bodies
        puck.position.x += puck.velocity.x * deltaTime
        puck.position.y += puck.velocity.y * deltaTime
        
        if !mallet.isGrabbed {
            mallet.position.x += mallet.velocity.x * deltaTime
            mallet.position.y += mallet.velocity.y * deltaTime
        }
        
        // MARK: Resolve overlapping
        resolveOverlap(grabbable: &mallet, freebody: &puck)
        constrainWithinWalls(&mallet)
        constrainWithinWalls(&puck)
    }
    
    //MARK: - Collisions
    
    private func collideWithWalls(_ b: inout Ball) {
        let r = b.radius
        if b.position.x - r <= 0
            || b.position.x + r >= boardSize.width {
            b.velocity.x = -b.velocity.x
        }
        
        if b.position.y - r <= 0
            || b.position.y + r >= boardSize.height {
            b.velocity.y = -b.velocity.y
        }
    }
    
    private func collideWithGrabbedBody(grabbed a: inout Ball, freeBody b: inout Ball) {
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
        }
    }
    
    private func collideBetweenFreeBodies(_ a: inout Ball, _ b: inout Ball) {
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
        }
    }
    
    //MARK: - Resolve Overlap
    
    private func resolveOverlap(grabbable a: inout Ball, freebody b: inout Ball) {
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
    
    private func constrainWithinWalls(_ b: inout Ball) {
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

extension AirHockeyPhysics: MultiGestureDetectorDelegate {
    func gestureDidStart(_ location: CGPoint) {
        mallet.position = location
        mallet.isGrabbed = true
        mallet.velocity = CGPoint.zero
    }
    
    func gestureDidMoveTo(_ location: CGPoint, velocity: CGPoint) {
        mallet.position = location
        mallet.isGrabbed = true
        mallet.velocity = (velocity / 7).clampingMagnitude(max: 300)
    }
    
    func gesturePanDidEnd(_ location: CGPoint, velocity: CGPoint) {
        mallet.position = location
        mallet.isGrabbed = false
        mallet.velocity = (velocity / 7).clampingMagnitude(max: 300)
    }
    
    func gesturePressDidEnd(_ location: CGPoint) {
        mallet.position = location
        mallet.isGrabbed = false
    }
}
