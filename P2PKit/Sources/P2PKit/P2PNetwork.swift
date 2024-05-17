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
        static let myMCPeerID = "com.P2PKit.MyMCPeerIDKey"
        static let myPeerID = "com.P2PKit.MyPeerIDKey"
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

public struct P2PNetwork {
    private static var session = P2PSession(myPeer: Peer.getMyPeer())
    private static let sessionListener = P2PNetworkSessionListener()

    // MARK: - Public P2PSession Getters
    
    // TODO: Set a device as session host
    public static var isHost: Bool = {
        return UIDevice.current.name == "iPhone"
    }()
    
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
    
    public static func peer(for peerID: MCPeerID) -> Peer? {
        return session.peer(for: peerID)
    }
    
    // MARK: - Public P2PSession Functions
    
    public static func connectionState(for peer: MCPeerID) -> MCSessionState? {
        session.connectionState(for: peer)
    }
    
    public static func resetSession(displayName: String? = nil) {
        prettyPrint(level: .error, "♻️ Resetting Session!")
        let oldSession = session
        oldSession.disconnect()
        
        let newPeerId = MCPeerID(displayName: displayName ?? oldSession.myPeer.displayName)
        let myPeer = Peer.resetMyPeer(with: newPeerId)
        session = P2PSession(myPeer: myPeer)
        session.delegate = sessionListener
        session.start()
    }
    
    public static func makeBrowserViewController() -> MCBrowserViewController {
        return session.makeBrowserViewController()
    }
    
    // MARK: - Delegates

    // If eventName is nil, the data delegate recieves all events
    public static func addDataDelegate(_ delegate: P2PNetworkDataDelegate, forEventName eventName: String = "") {
        sessionListener.addDataDelegate(delegate, eventName: eventName)
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
    
    // MARK: - Internal - Send and Receive Events

    static func send<T: Codable>(eventName: String, payload: T, senderID: String?, to peers: [MCPeerID] = [], reliable: Bool) -> EventInfo {
        let eventInfo = EventInfo(
            senderEntityID: senderID,
            sendTime: Date().timeIntervalSince1970)
        session.send(Event(eventName: eventName,
                           info: eventInfo,
                           payload: payload),
                     to: peers,
                     reliable: reliable)
        return eventInfo
    }
    
    // If eventName is empty, receive callbacks on all events
    static func onReceive<T: Codable>(eventName: String, _ callback: @escaping (_ eventInfo: EventInfo, _ payload: T, _ json: [String: Any]?, _ sender: Peer) -> Void) -> OnReceivedHandler {
        
        let castedCallback: OnReceivedHandler.Callback = { (data, json, sender) in
            do {
                let event = try JSONDecoder().decode(Event<T>.self, from: data)
                if event.eventName == eventName {
                    callback(event.info, event.payload, json, sender)
                }
            } catch {
                fatalError("Could not decode event of type \(Event<T>.self).\nJSON: \(String(describing: json))")
            }
        }
        
        let handler = OnReceivedHandler(callback: castedCallback)
        sessionListener.onReceivedData(handler, eventName: eventName)
        return handler
    }
}

private class P2PNetworkSessionListener {
    private var peerDelegates = [WeakPeerDelegate]()
    
    private var dataDelegates = [String: [WeakDataDelegate]]()
    
    private var onReceiveHandlers = [String: [Weak<OnReceivedHandler>]]()
        
    fileprivate func onReceivedData(_ handler: OnReceivedHandler, eventName: String) {
        let eventName = !eventName.isEmpty ? eventName : ""
        if let handlers = onReceiveHandlers[eventName] {
            let isInArray = handlers.contains { $0.ref === handler }
            if !isInArray {
                onReceiveHandlers[eventName]?.append(Weak<OnReceivedHandler>(handler))
                onReceiveHandlers[eventName]?.removeAll(where: { $0.ref?.callback == nil })
            }
        } else {
            onReceiveHandlers[eventName] = [Weak<OnReceivedHandler>(handler)]
        }
    }
    
    fileprivate func addDataDelegate(_ delegate: P2PNetworkDataDelegate, eventName: String) {
        let eventName = eventName ?? ""
        if dataDelegates[eventName] != nil {
            if !dataDelegates[eventName]!.contains(where: { $0.delegate === delegate }) {
                dataDelegates[eventName]!.append(WeakDataDelegate(delegate))
            }
            dataDelegates[eventName]!.removeAll(where: { $0.delegate == nil })
        } else {
            dataDelegates[eventName] = [WeakDataDelegate(delegate)]
        }
    }
    
    fileprivate func removeDataDelegate(_ delegate: P2PNetworkDataDelegate) {
        for key in dataDelegates.keys {
            dataDelegates[key]?.removeAll(where: { $0.delegate === delegate })
        }
    }
    
    fileprivate func addPeerDelegate(_ delegate: P2PNetworkPeerDelegate) {
        if !peerDelegates.contains(where: { $0.delegate === delegate }) {
            peerDelegates.append(WeakPeerDelegate(delegate))
        }
        peerDelegates.removeAll(where: { $0.delegate == nil })
        delegate.p2pNetwork(didUpdate: P2PNetwork.myPeer)
    }
    
    fileprivate func removePeerDelegate(_ delegate: P2PNetworkPeerDelegate) {
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
        if let eventName = json?["eventName"] as? String {
            if let wrappers = dataDelegates[eventName] {
                for wrapper in wrappers {
                    wrapper.delegate?.p2pNetwork(didReceive: data, dataAsJson: json, from: peer)
                }
            }
            
            if let wrappers = onReceiveHandlers[eventName] {
                for wrapper in wrappers {
                    wrapper.ref?.callback(data, json, peer)
                }
            }
        }
        
        if let wrappers = dataDelegates[""] {
            for wrapper in wrappers {
                wrapper.delegate?.p2pNetwork(didReceive: data, dataAsJson: json, from: peer)
            }
        }
    }
}

class OnReceivedHandler {
    fileprivate typealias Callback = (_ data: Data, _ dataAsJson: [String : Any]?, _ fromPeer: Peer) -> Void

    fileprivate var callback: Callback

    fileprivate init(callback: @escaping Callback) {
        self.callback = callback
    }
}

private struct Event<T: Codable>: Codable {
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

private class Weak<T: AnyObject> {
    weak var ref: T?
    
    init(_ ref: T) {
        self.ref = ref
    }
}
