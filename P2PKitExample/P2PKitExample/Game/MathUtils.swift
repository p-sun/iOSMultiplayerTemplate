//
//  CGPoint+extensions.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/9/24.
//

import Foundation

extension CGPoint {
    // Vector addition
    static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    // Vector subtraction
    static func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    // Scalar multiplication
    static func *(vector: CGPoint, scalar: CGFloat) -> CGPoint {
        return CGPoint(x: vector.x * scalar, y: vector.y * scalar)
    }
    
    // Scalar division
    static func /(vector: CGPoint, scalar: CGFloat) -> CGPoint {
        return CGPoint(x: vector.x / scalar, y: vector.y / scalar)
    }
    
    func normalized() -> CGPoint {
        let length = sqrt(x * x + y * y)
        return length > 0 ? CGPoint(x: x / length, y: y / length) : CGPoint.zero
    }
    
    func magnitude() -> CGFloat {
        return sqrt(x * x + y * y)
    }
    
    func clampingMagnitude(min: CGFloat = -CGFloat.infinity, max: CGFloat = CGFloat.infinity) -> CGPoint {
        let curr = sqrt(x * x + y * y)
        if curr >= min && curr <= max || curr == 0 {
            return self
        }
        let scale = curr < min ? (min / curr) : (max / curr)
        return CGPoint(x: x * scale, y: y * scale)
    }
}

extension CGFloat {
    func clamp(min: CGFloat = -CGFloat.infinity, max: CGFloat = CGFloat.infinity) -> CGFloat {
        return CGFloat.maximum(min, CGFloat.minimum(self, max))
    }
}
