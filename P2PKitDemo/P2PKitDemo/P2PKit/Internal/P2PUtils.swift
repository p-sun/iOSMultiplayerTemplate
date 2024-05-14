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

extension View {
    func p2pButtonStyle() -> some View {
        self.buttonStyle(.borderedProminent).tint(.mint)
    }
}

extension Text {
    public func p2pTitleStyle() -> some View {
        return self.font(.title)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(EdgeInsets(top: 14, leading: 0, bottom: 0, trailing: 0))
    }
}
