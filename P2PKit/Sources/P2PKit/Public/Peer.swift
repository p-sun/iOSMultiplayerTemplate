//
//  Player.swift
//  P2PKitExample
//
//  Created by Paige Sun on 4/24/24.
//

import MultipeerConnectivity

public struct Peer {
    public let peerID: MCPeerID
    public var displayName: String { return peerID.displayName }
    
    public init(_ peerID: MCPeerID) {
        self.peerID = peerID
    }
}

extension Peer: Hashable {
    public static func == (lhs: Peer, rhs: Peer) -> Bool {
        return lhs.peerID == rhs.peerID
    }
    
    public func hash(into hasher: inout Hasher) {
        peerID.hash(into: &hasher)
    }
}

extension UserDefaults {
    var myPeer: Peer {
        get {
            if let data = data(forKey: P2PConstants.UserDefaultsKeys.myPeer),
               let peerID = try! NSKeyedUnarchiver.unarchivedObject(ofClass: MCPeerID.self, from: data) {
                return Peer(peerID)
            } else {
                let randomAnimal = Array("🦊🐯🐹🐶🐸🐵🐮🦄").randomElement()!
                let peerID = MCPeerID(displayName: "\(randomAnimal) \(UIDevice.current.name)")
                let data = try! NSKeyedArchiver.archivedData(withRootObject: peerID, requiringSecureCoding: true)
                set(data, forKey: P2PConstants.UserDefaultsKeys.myPeer)
                return Peer(peerID)
            }
        }
        set {
            let data = try! NSKeyedArchiver.archivedData(withRootObject: newValue.peerID, requiringSecureCoding: true)
            set(data, forKey: P2PConstants.UserDefaultsKeys.myPeer)
        }
    }
}
