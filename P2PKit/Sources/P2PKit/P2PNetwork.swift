//
//  P2PNetwork.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/2/24.
//

import Foundation
import MultipeerConnectivity

public struct P2PConstants {
    public static var networkChannelName = "my-p2p-service"
    public static var loggerEnabled = true
    
    struct UserDefaultsKeys {
        static let myPeer = "com.P2PKit.MyPeerIDKey"
    }
}

public protocol P2PNetworkDataDelegate: AnyObject {
    func p2pNetwork(didReceive data: Data, dataAsJson json: [String: Any]?, from peer: Peer) -> Bool
}

public protocol P2PNetworkPeerDelegate: AnyObject {
    func p2pNetwork(didUpdate peer: Peer) -> Void
}

public struct EventInfo: Codable {
    public let senderEntityID: String?
    public let sendTime: Double
}

public class P2PNetwork {
    private static var session = P2PSession(myPeer: UserDefaults.standard.myPeer)
    private static let sessionListener = P2PNetworkSessionListener()
    
    private static var eventListeners = [String: [(Any) -> Void]]()
    
    public static var myPeer: Peer {
        return session.myPeer
    }
    
    public static var connectedPeers: [Peer] {
        return session.connectedPeers
    }
    
    public static var allPeers: [Peer] {
        return session.allPeers
    }
    
    public static func start() {
        if session.delegate == nil {
            session.delegate = sessionListener
            session.start()
        }
    }
    
    public static func sendEvent<T: Codable>(eventName: String, payload: T, senderID: String?, to peers: [MCPeerID] = []) -> EventInfo {
        let eventInfo = EventInfo(senderEntityID: senderID, sendTime: Date().timeIntervalSince1970)
        session.send(Event(eventName: eventName,
                           info: eventInfo,
                           payload: payload),
                     to: peers)
        return eventInfo
    }
    
    public static func onEventReceived<T: Decodable>(eventName: String, callback: @escaping (T) -> Void) {
        
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
    public static func addDataDelegate(_ delegate: P2PNetworkDataDelegate, forEventName eventName: String? = nil) {
        sessionListener.addDataDelegate(delegate, forEventName: eventName)
    }
    
    public static func removeDataDelegate(_ delegate: P2PNetworkDataDelegate) {
        sessionListener.removeDataDelegate(delegate)
    }
    
    public static func addPeerDelegate(_ delegate: P2PNetworkPeerDelegate) {
        sessionListener.addPeerDelegate(delegate)
    }
    
    public static func removePeerDelegate(_ delegate: P2PNetworkPeerDelegate) {
        sessionListener.removePeerDelegate(delegate)
    }
    
    public static func connectionState(for peer: MCPeerID) -> MCSessionState? {
        session.connectionState(for: peer)
    }
    
    public static func resetSession(displayName: String? = nil) {
        prettyPrint(level: .error, "♻️ Resetting Session!")
        let oldSession = session
        oldSession.disconnect()
        
        let newPeerId = MCPeerID(displayName: displayName ?? oldSession.myPeer.displayName)
        let myPeer = Peer(newPeerId)
        UserDefaults.standard.myPeer = myPeer
        
        session = P2PSession(myPeer: myPeer)
        session.delegate = sessionListener
        session.start()
    }
    
    public static func makeBrowserViewController() -> MCBrowserViewController {
        return session.makeBrowserViewController()
    }
}

private class P2PNetworkSessionListener {
    private var peerDelegates = [WeakPeerDelegate]()
    
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
    
    func addPeerDelegate(_ delegate: P2PNetworkPeerDelegate) {
        if !peerDelegates.contains(where: { $0.delegate === delegate }) {
            peerDelegates.append(WeakPeerDelegate(delegate))
        }
        peerDelegates.removeAll(where: { $0.delegate == nil })
    }
    
    func removePeerDelegate(_ delegate: P2PNetworkPeerDelegate) {
        peerDelegates.removeAll(where: { $0.delegate === delegate || $0.delegate == nil })
    }
}

extension P2PNetworkSessionListener: P2PSessionDelegate {
    func p2pSession(_ session: P2PSession, didUpdate peer: Peer) {
        for peerDelegateWrapper in peerDelegates {
            peerDelegateWrapper.delegate?.p2pNetwork(didUpdate: peer)
        }
    }
    
    func p2pSession(_ session: P2PSession, didReceive data: Data, dataAsJson json: [String : Any]?, from peer: Peer) {
        for wrapper in dataDelegatesAllEvents {
            if wrapper.delegate?.p2pNetwork(didReceive: data, dataAsJson: json, from: peer) == true {
                return
            }
        }
        
        if let eventName = json?["eventName"] as? String,
           let wrappers = dataDelegates[eventName] {
            for wrapper in wrappers {
                if wrapper.delegate?.p2pNetwork(didReceive: data, dataAsJson: json, from: peer) == true {
                    return
                }
            }
        }        
    }
}

struct Event<T: Codable>: Codable {
    let eventName: String
    let info: EventInfo
    let payload: T
}

private class WeakDataDelegate {
    weak var delegate: P2PNetworkDataDelegate?
    
    init(_ delegate: P2PNetworkDataDelegate) {
        self.delegate = delegate
    }
}

private class WeakPeerDelegate {
    weak var delegate: P2PNetworkPeerDelegate?
    
    init(_ delegate: P2PNetworkPeerDelegate) {
        self.delegate = delegate
    }
}

private class WeakRef<T: AnyObject> {
    weak var delegate: T?
    
    init(_ delegate: T) {
        self.delegate = delegate
    }
}
