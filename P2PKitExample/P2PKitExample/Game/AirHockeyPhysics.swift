//
//  AirHockeyPhysics.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/9/24.
//

import Foundation

struct Ball {
    var center: CGPoint
    var velocity: CGVector
}

class AirHockeyPhysics {
    private(set) var ball: Ball
    var handle: Ball
    
    private let boardSize: CGSize
    private let ballRadius: CGFloat
    private let handleRadius: CGFloat
    
    init(boardSize: CGSize, ballRadius: CGFloat, handleRadius: CGFloat) {
        self.ball = Ball(center: CGPoint(x: boardSize.width/2,
                                           y: boardSize.height/2),
                         velocity: GameConfig.ballInitialVelocity)
        self.handle = Ball(center: CGPoint(x: boardSize.width/2,
                                           y: boardSize.height - 80),
                           velocity: CGVector.zero)
        self.boardSize = boardSize
        self.ballRadius = ballRadius
        self.handleRadius = handleRadius
    }
    
    func update() {
        ball.center.x += ball.velocity.dx
        ball.center.y += ball.velocity.dy
        
        constrainHandleWithinWalls()
        checkBallCollisionsWithWalls()
        checkCollisionsBetween(&ball, &handle)
    }
    
    private func constrainHandleWithinWalls() {
        let r = handleRadius
        if handle.center.x - r <= 0 {
            handle.center.x = r
        }
        if handle.center.x + r >= boardSize.width {
            handle.center.x = boardSize.width - r
        }
        if handle.center.y - r <= 0 {
            handle.center.y = r
        }
        if handle.center.y + r >= boardSize.height {
            handle.center.y = boardSize.height - r
        }
    }
    
    private func checkBallCollisionsWithWalls() {
        let r = ballRadius
        if ball.center.x - r <= 0
            || ball.center.x + r >= boardSize.width {
            ball.velocity.dx = -ball.velocity.dx
        }
        
        if ball.center.y - r <= 0
            || ball.center.y + r >= boardSize.height {
            ball.velocity.dy = -ball.velocity.dy
        }
    }
    
    private func checkCollisionsBetween(_ a: inout Ball, _ b: inout Ball) {
        
    }
}
