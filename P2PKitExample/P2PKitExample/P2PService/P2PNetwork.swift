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

protocol P2PNetworkDataDelegate: AnyObject {
    func p2pNetwork(didReceive data: Data, dataAsJson json: [String: Any]?, from player: Player) -> Bool
}

protocol P2PNetworkPlayerDelegate: AnyObject {
    func p2pNetwork(didUpdate player: Player) -> Void
}

class P2PNetwork {
    private static var session = P2PSession(myPlayer: UserDefaults.standard.myPlayer)
    private static let sessionListener = P2PNetworkSessionListener()
    
    private static var eventListeners = [String: [(Any) -> Void]]()
    
    static var myPlayer: Player {
        return session.myPlayer
    }
    
    static var allPeers: [Player] {
        return session.allPeers
    }
    
    static func start() {
        session.delegate = sessionListener
        session.start()
    }
    
    static func sendEvent<T: Codable>(eventName: String, payload: T, senderID: String?, to peers: [MCPeerID] = []) -> EventInfo {
        let eventInfo = EventInfo(senderEntityID: senderID, sendTime: Date().timeIntervalSince1970)
        session.send(Event(eventName: eventName,
                           info: eventInfo,
                           payload: payload),
                     to: peers)
        return eventInfo
    }
    
    static func onEventReceived<T: Decodable>(eventName: String, callback: @escaping (T) -> Void) {
        
        let castedCallback: (Any) -> Void = { any in
            guard let value = any as? T else {
                fatalError("Type mismatch, expected \(T.self) but received \(type(of: any))")
            }
            callback(value)
        }
        
        if eventListeners[eventName] == nil {
            eventListeners[eventName] = [castedCallback]
        } else {
            eventListeners[eventName]?.append(castedCallback)
        }
    }
    
    // If eventName is nil, the data delegate recieves all events
    static func addDataDelegate(_ delegate: P2PNetworkDataDelegate, forEventName eventName: String? = nil) {
        sessionListener.addDataDelegate(delegate, forEventName: eventName)
    }
    
    static func removeDataDelegate(_ delegate: P2PNetworkDataDelegate) {
        sessionListener.removeDataDelegate(delegate)
    }
    
    static func addPlayerDelegate(_ delegate: P2PNetworkPlayerDelegate) {
        sessionListener.addPlayerDelegate(delegate)
    }
    
    static func removePlayerDelegate(_ delegate: P2PNetworkPlayerDelegate) {
        sessionListener.removePlayerDelegate(delegate)
    }
    
    static func connectionState(for peer: MCPeerID) -> MCSessionState? {
        session.connectionState(for: peer)
    }
    
    static func resetSession(displayName: String? = nil) {
        prettyPrint(level: .error, "♻️ Resetting Session!")
        let oldSession = session
        oldSession.disconnect()
        
        let newPeerId = MCPeerID(displayName: displayName ?? oldSession.myPlayer.displayName)
        let myPlayer = Player(newPeerId)
        UserDefaults.standard.myPlayer = myPlayer
        
        session = P2PSession(myPlayer: myPlayer)
        session.delegate = sessionListener
        session.start()
    }
    
    static func makeBrowserViewController() -> MCBrowserViewController {
        return session.makeBrowserViewController()
    }
}

private class P2PNetworkSessionListener {
    private var playerDelegates = [WeakPlayerDelegate]()
    
    // Delegates for specific Event with event name
    private var dataDelegates = [String: [WeakDataDelegate]]()
    // Delegates for all events
    private var dataDelegatesAllEvents = [WeakDataDelegate]()
    
    // MARK: - Delegates
    
    func addDataDelegate(_ delegate: P2PNetworkDataDelegate, forEventName eventName: String? = nil) {
        if let eventName = eventName {
            if dataDelegates[eventName] != nil {
                if !dataDelegates[eventName]!.contains(where: { $0.delegate === delegate }) {
                    dataDelegates[eventName]!.append(WeakDataDelegate(delegate))
                }
                dataDelegates[eventName]!.removeAll(where: { $0.delegate == nil })
            } else {
                dataDelegates[eventName] = [WeakDataDelegate(delegate)]
            }
        } else {
            if !dataDelegatesAllEvents.contains(where: { $0.delegate === delegate }) {
                dataDelegatesAllEvents.append(WeakDataDelegate(delegate))
            }
            dataDelegatesAllEvents.removeAll(where: { $0.delegate == nil })
        }
    }
    
    func removeDataDelegate(_ delegate: P2PNetworkDataDelegate) {
        dataDelegatesAllEvents.removeAll(where: { $0.delegate === delegate })
        
        for key in dataDelegates.keys {
            dataDelegates[key]?.removeAll(where: { $0.delegate === delegate })
        }
    }
    
    func addPlayerDelegate(_ delegate: P2PNetworkPlayerDelegate) {
        if !playerDelegates.contains(where: { $0.delegate === delegate }) {
            playerDelegates.append(WeakPlayerDelegate(delegate))
        }
        playerDelegates.removeAll(where: { $0.delegate == nil })
    }
    
    func removePlayerDelegate(_ delegate: P2PNetworkPlayerDelegate) {
        playerDelegates.removeAll(where: { $0.delegate === delegate || $0.delegate == nil })
    }
}

extension P2PNetworkSessionListener: P2PSessionDelegate {
    func p2pSession(_ session: P2PSession, didUpdate player: Player) {
        for playerDelegateWrapper in playerDelegates {
            playerDelegateWrapper.delegate?.p2pNetwork(didUpdate: player)
        }
    }
    
    func p2pSession(_ session: P2PSession, didReceive data: Data, dataAsJson json: [String : Any]?, from player: Player) {
        for wrapper in dataDelegatesAllEvents {
            if wrapper.delegate?.p2pNetwork(didReceive: data, dataAsJson: json, from: player) == true {
                return
            }
        }
        
        if let eventName = json?["eventName"] as? String,
           let wrappers = dataDelegates[eventName] {
            for wrapper in wrappers {
                if wrapper.delegate?.p2pNetwork(didReceive: data, dataAsJson: json, from: player) == true {
                    return
                }
            }
        }        
    }
}

private class WeakDataDelegate {
    weak var delegate: P2PNetworkDataDelegate?
    
    init(_ delegate: P2PNetworkDataDelegate) {
        self.delegate = delegate
    }
}

private class WeakPlayerDelegate {
    weak var delegate: P2PNetworkPlayerDelegate?
    
    init(_ delegate: P2PNetworkPlayerDelegate) {
        self.delegate = delegate
    }
}

private class WeakRef<T: AnyObject> {
    weak var delegate: T?
    
    init(_ delegate: T) {
        self.delegate = delegate
    }
}
