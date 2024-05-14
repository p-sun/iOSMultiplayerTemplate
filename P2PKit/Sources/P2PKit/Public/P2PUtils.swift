//
//  P2PUtils.swift
//  P2PKitExample
//
//  Created by Paige Sun on 4/24/24.
//

import Foundation
import MultipeerConnectivity
import SwiftUI

extension MCSessionState: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
            case .connecting:   return "Connecting"
            case .connected:    return "Connected"
            case .notConnected: return "NotConnected"
            @unknown default:   return "Unknown"
        }
    }
}
