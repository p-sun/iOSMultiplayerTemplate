//
//  AirHockeyPhysics.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/9/24.
//

import Foundation

struct Ball {
    let radius: CGFloat
    let mass: CGFloat
    var velocity: CGPoint
    var position: CGPoint
    var framesSinceCollision = 0
}

class AirHockeyPhysics {
    private(set) var ball: Ball
    var handle: Ball
    
    private let boardSize: CGSize
    
    init(boardSize: CGSize, ballRadius: CGFloat, handleRadius: CGFloat) {
        self.ball = Ball(radius: ballRadius,
                         mass: GameConfig.ballMass,
                         velocity: GameConfig.ballInitialVelocity,
                         position: CGPoint(x: boardSize.width/2,
                                           y: boardSize.height/2))
        self.handle = Ball(radius: handleRadius,
                           mass: GameConfig.handleMass,
                           velocity: CGPoint.zero,
                           position: CGPoint(
                            x: boardSize.width/2,
                            y: boardSize.height - 80))
        self.boardSize = boardSize
    }
    
    func update(duration: CGFloat) {
        // MARK: Collisions updates velocity
        if isColliding(ball, handle) {
            if ball.framesSinceCollision > 10 {
                ball.framesSinceCollision = 0
                handle.framesSinceCollision = 0
                collideBetween(&ball, &handle)
            }
        } else {
            ball.framesSinceCollision += 1
            handle.framesSinceCollision += 1
        }
        
        collideWithWalls(&ball)
        collideWithWalls(&handle)
        
        ball.velocity = ball.velocity.capMagnitudeTo(min: 200, max: 1200)
        
        // MARK: Update Position
        ball.position.x += ball.velocity.x * duration
        ball.position.y += ball.velocity.y * duration
        handle.position.x += handle.velocity.x * duration
        handle.position.y += handle.velocity.y * duration
        
        // MARK: Reduce Overlapping of objects
        if isColliding(ball, handle) {
            moveApart(&ball, &handle)
        }
        constrainWithinWalls(&handle)
        constrainWithinWalls(&ball)
    }
    
    private func constrainWithinWalls(_ o: inout Ball) {
        let r = o.radius
        if o.position.x - r <= 0 {
            o.position.x = r
        }
        if o.position.x + r >= boardSize.width {
            o.position.x = boardSize.width - r
        }
        if o.position.y - r <= 0 {
            o.position.y = r
        }
        if o.position.y + r >= boardSize.height {
            o.position.y = boardSize.height - r
        }
    }
    
    private func collideWithWalls(_ o: inout Ball) {
        let r = o.radius
        if o.position.x - r <= 0
            || o.position.x + r >= boardSize.width {
            o.velocity.x = -o.velocity.x
        }
        
        if o.position.y - r <= 0
            || o.position.y + r >= boardSize.height {
            o.velocity.y = -o.velocity.y
        }
    }
    
    private func isColliding(_ a: Ball, _ b: Ball) -> Bool {
        let dx = b.position.x - a.position.x
        let dy = b.position.y - a.position.y
        let distance = sqrt(dx * dx + dy * dy)
        return distance <= (a.radius + b.radius)
    }
    
    private func moveApart(_ a: inout Ball, _ b: inout Ball) {
        let aToB = b.position - a.position
        let aToBDir = aToB.normalized()
        let shiftByVector = aToBDir * (a.radius + b.radius - aToB.magnitude())
        // Move the lighter ball away (TODO: add a 'isGrabbed' on the ball)
        if b.mass < a.mass {
            b.position = b.position + shiftByVector
        } else {
            a.position = a.position - shiftByVector
        }
    }
    
    private func collideBetween(_ a: inout Ball, _ b: inout Ball) {
        let dx = b.position.x - a.position.x
        let dy = b.position.y - a.position.y
        let distance = sqrt(dx * dx + dy * dy)
        
        if distance <= (a.radius + b.radius) {
            // Normal vector
            let nx = dx / distance
            let ny = dy / distance
            
            // Tangential vector
            let tx = -ny
            let ty = nx
            
            // Dot product tangent
            let dpTan1 = a.velocity.x * tx + a.velocity.y * ty
            let dpTan2 = b.velocity.x * tx + b.velocity.y * ty
            
            // Dot product normal
            let dpNorm1 = a.velocity.x * nx + a.velocity.y * ny
            let dpNorm2 = b.velocity.x * nx + b.velocity.y * ny
            
            // Conservation of momentum in 1D
            let m1 = (dpNorm1 * (a.mass - b.mass) + 2 * b.mass * dpNorm2) / (a.mass + b.mass)
            let m2 = (dpNorm2 * (b.mass - a.mass) + 2 * a.mass * dpNorm1) / (a.mass + b.mass)
            
            // Update velocities
            a.velocity.x = tx * dpTan1 + nx * m1
            a.velocity.y = ty * dpTan1 + ny * m1
            b.velocity.x = tx * dpTan2 + nx * m2
            b.velocity.y = ty * dpTan2 + ny * m2
        }
    }
}
