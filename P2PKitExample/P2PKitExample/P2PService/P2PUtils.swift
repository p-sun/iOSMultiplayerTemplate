//
//  P2PUtils.swift
//  P2PKitExample
//
//  Created by Paige Sun on 4/24/24.
//

import Foundation
import MultipeerConnectivity
import SwiftUI

struct UserDefaultsKeys {
    static let myPeerId = "MyPeerIDDefaultsKey"
}

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

extension Text {
    public func p2pTitleStyle() -> some View {
        return self.font(.title).bold()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(EdgeInsets(top: 12, leading: 0, bottom: 0, trailing: 0))
    }
}
