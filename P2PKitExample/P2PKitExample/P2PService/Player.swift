//
//  Player.swift
//  P2PKitExample
//
//  Created by Paige Sun on 4/24/24.
//

import MultipeerConnectivity

struct Player {
    let peerID: MCPeerID
    var username: String { return peerID.displayName }

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

extension Player {
    static var myself: Player = {
        if let data = UserDefaults.standard.data(forKey: UserDefaultsKeys.myPeerId),
            let peerID = try? NSKeyedUnarchiver.unarchivedObject(ofClass: MCPeerID.self, from: data) {
            return Player(peerID)
        } else {
            let peerID = MCPeerID(displayName: UIDevice.current.name)
            let data = try? NSKeyedArchiver.archivedData(withRootObject: peerID, requiringSecureCoding: true)
            UserDefaults.standard.set(data, forKey: UserDefaultsKeys.myPeerId)
            return Player(peerID)
        }
    }()
}
