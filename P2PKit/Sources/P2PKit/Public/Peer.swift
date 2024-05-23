//
//  Peer.swift
//  P2PKitExample
//
//  Created by Paige Sun on 4/24/24.
//

import MultipeerConnectivity

public struct Peer {
    public typealias Identifier = String

    public let id: Identifier
    public let peerID: MCPeerID
    public var displayName: String { return peerID.displayName }
    
    public init(_ peerID: MCPeerID, id: String) {
        self.id = id
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
 
// My Peer
extension Peer {
    static func getMyPeer() -> Peer {
        if let data = UserDefaults.standard.data(forKey: P2PConstants.UserDefaultsKeys.myMCPeerID),
           let peerID = try! NSKeyedUnarchiver.unarchivedObject(ofClass: MCPeerID.self, from: data),
           let id = UserDefaults.standard.string(forKey: P2PConstants.UserDefaultsKeys.myPeerID) {
            return Peer(peerID, id: id)
        } else {
            let randomAnimal = Array("🦊🐯🐹🐶🐸🐵🐮🦄").randomElement()!
            let peerID = MCPeerID(displayName: "\(randomAnimal) \(UIDevice.current.name)")
            return resetMyPeer(with: peerID)
        }
    }
    
    static func resetMyPeer(with peerID: MCPeerID) -> Peer
    {
        let data = try! NSKeyedArchiver.archivedData(withRootObject: peerID, requiringSecureCoding: true)
        let id = UIDevice.current.identifierForVendor!.uuidString
        UserDefaults.standard.set(data, forKey: P2PConstants.UserDefaultsKeys.myMCPeerID)
        UserDefaults.standard.set(id, forKey: P2PConstants.UserDefaultsKeys.myPeerID)
        return Peer(peerID, id: id)
    }
}
