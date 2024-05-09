//
//  AirHockeyPhysics.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/9/24.
//

import Foundation

struct Ball {
    var position: CGPoint
    var velocity: CGVector
}

class AirHockeyPhysics {
    private(set) var ball: Ball
    
    private let boardSize: CGSize
    private let ballRadius: CGFloat
    
    init(boardSize: CGSize, ballRadius: CGFloat) {
        self.ball = Ball(position: CGPoint(x: boardSize.width/2,
                                           y: boardSize.height/2),
                     velocity: GameConfig.ballInitialVelocity)
        self.boardSize = boardSize
        self.ballRadius = ballRadius
    }
    
    func update() {
        ball.position.x += ball.velocity.dx
        ball.position.y += ball.velocity.dy
        checkWallCollisions()
    }
    
    private func checkWallCollisions() {
        if ball.position.x - ballRadius <= 0
            || ball.position.x + ballRadius >= boardSize.width {
            ball.velocity.dx = -ball.velocity.dx
        }
        
        if ball.position.y - ballRadius <= 0
            || ball.position.y + ballRadius >= boardSize.height {
            ball.velocity.dy = -ball.velocity.dy
        }
    }
}
