//
//  NetworkingEvents.swift
//  P2PKitDemo
//
//  Created by Paige Sun on 5/16/24.
//

import Foundation

struct MalletDragEvent: Codable {
    let tag: Int
    let isGrabbed: Bool
    let position: CGPoint
    let velocity: CGPoint?
}
