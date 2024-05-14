//
//  Player.swift
//  P2PKitExample
//
//  Created by Paige Sun on 4/24/24.
//

import MultipeerConnectivity

struct Player {
    let peerID: MCPeerID
    var displayName: String { return peerID.displayName }
    
    init(_ peerID: MCPeerID) {
        self.peerID = peerID
    }
}

extension Player: Hashable {
    static func == (lhs: Player, rhs: Player) -> Bool {
        return lhs.peerID == rhs.peerID
    }
    
    func hash(into hasher: inout Hasher) {
        peerID.hash(into: &hasher)
    }
}

extension UserDefaults {
    var myPlayer: Player {
        get {
            if let data = data(forKey: P2PConstants.UserDefaultsKeys.myPlayer),
               let peerID = try! NSKeyedUnarchiver.unarchivedObject(ofClass: MCPeerID.self, from: data) {
                return Player(peerID)
            } else {
                let randomAnimal = Array("🦊🐯🐹🐶🐸🐵🐮🦄").randomElement()!
                let peerID = MCPeerID(displayName: "\(randomAnimal) \(UIDevice.current.name)")
                let data = try! NSKeyedArchiver.archivedData(withRootObject: peerID, requiringSecureCoding: true)
                set(data, forKey: P2PConstants.UserDefaultsKeys.myPlayer)
                return Player(peerID)
            }
        }
        set {
            let data = try! NSKeyedArchiver.archivedData(withRootObject: newValue.peerID, requiringSecureCoding: true)
            set(data, forKey: P2PConstants.UserDefaultsKeys.myPlayer)
        }
    }
}
