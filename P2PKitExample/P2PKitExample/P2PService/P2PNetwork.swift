//
//  P2PNetwork.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/2/24.
//

import Foundation
import MultipeerConnectivity

struct P2PConstants {
    static let networkChannelName = "my-p2p-service"
    static let loggerEnabled = true
    
    struct UserDefaultsKeys {
        static let myPlayer = "MyPlayerIDKey"
    }
}

class P2PNetwork {
    private static var session = P2PSession(myPlayer: UserDefaults.standard.myPlayer)
    
    static var myPlayer: Player {
        return session.myPlayer
    }
    
    static func start() {
        session.start()
    }
    
    static func send(_ encodable: Encodable, to peers: [MCPeerID] = []) {
        session.send(encodable, to: peers)
    }
    
    static func send(data: Data, to peers: [MCPeerID] = []) {
        session.send(data: data, to: peers)
    }
    
    static func addDelegate(_ delegate: P2PSessionDelegate) {
        session.addDelegate(delegate)
    }
    
    static func removeDelegate(_ delegate: P2PSessionDelegate) {
        session.removeDelegate(delegate)
    }
    
    static func connectionState(for peer: MCPeerID) -> MCSessionState? {
        session.connectionState(for: peer)
    }
    
    static func resetSession(displayName: String? = nil) {
        let oldSession = session
        oldSession.disconnect()
        
        let newPeerId = MCPeerID(displayName: displayName ?? oldSession.myPlayer.displayName)
        let myPlayer = Player(newPeerId)
        UserDefaults.standard.myPlayer = myPlayer
        
        session = P2PSession(myPlayer: myPlayer)
        for delegate in oldSession.delegates {
            oldSession.removeDelegate(delegate)
            session.addDelegate(delegate)
        }
        
        session.start()
    }
    
    static func makeBrowserViewController() -> MCBrowserViewController {
        return session.makeBrowserViewController()
    }
}
