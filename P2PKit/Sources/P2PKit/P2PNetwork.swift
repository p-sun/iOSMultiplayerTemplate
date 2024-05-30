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

public protocol P2PNetworkPeerDelegate: AnyObject {
    func p2pNetwork(didUpdate peer: Peer) -> Void
    func p2pNetwork(didUpdateHost host: Peer?) -> Void
}

public struct EventInfo: Codable {
    public let senderEntityID: String?
    public let sendTime: Double
}

public struct P2PNetwork {
    private static var session = P2PSession(myPeer: Peer.getMyPeer())
    private static let sessionListener = P2PNetworkSessionListener()
    private static let hostSelector = {
        let hostSelector = P2PHostSelector()
        hostSelector.didUpdateHost = { host in
            sessionListener.notifyPeerDelegateOfHostUpdate(host)
        }
        return hostSelector
    }()

    // MARK: - Public P2PHostService
    
    public static var host: Peer? {
        return hostSelector.host
    }
        
    public static func makeMeHost() {
        hostSelector.makeMeHost()
    }
    
    // MARK: - Public P2PSession Getters

    public static var myPeer: Peer {
        return session.myPeer
    }
    
    // Connected Peers, not including self
    public static var connectedPeers: [Peer] {
        return soloMode ? soloModePeers : session.connectedPeers
    }
    
    // Debug only, use connectedPeers instead.
    public static var allPeers: [Peer] {
        return session.allPeers
    }
    
    // When true, fake connectedPeers, and disallow sending and receiving.
    public static var soloMode = false
    private static var soloModePeers = {
       return [Peer(MCPeerID(displayName: "Player 1"), id: "Player 1"),
               Peer(MCPeerID(displayName: "Player 2"), id: "Player 2")]
    }()
    
    // MARK: - Public P2PSession Management

    public static func start() {
        if session.delegate == nil {
            P2PNetwork.hostSelector
            session.delegate = sessionListener
            session.start()
        }
    }
    
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
    
    // MARK: - Peer Delegates

    public static func addPeerDelegate(_ delegate: P2PNetworkPeerDelegate) {
        sessionListener.addPeerDelegate(delegate)
    }
    
    public static func removePeerDelegate(_ delegate: P2PNetworkPeerDelegate) {
        sessionListener.removePeerDelegate(delegate)
    }

    // MARK: - Internal - Send and Receive Events
    
    static func send(_ encodable: Encodable, to peers: [MCPeerID] = [], reliable: Bool) {
        guard !soloMode else { return }
        session.send(encodable, to: peers, reliable: reliable)
    }
    
    static func sendData(_ data: Data, to peers: [MCPeerID] = [], reliable: Bool) {
        guard !soloMode else { return }
        session.send(data: data, to: peers, reliable: reliable)
    }
    
    static func onReceiveData(eventName: String, _ callback: @escaping DataHandler.Callback) -> DataHandler {
        sessionListener.onReceiveData(eventName: eventName, callback)
    }
}

class DataHandler {
    typealias Callback = (_ data: Data, _ dataAsJson: [String : Any]?, _ fromPeerID: MCPeerID) -> Void
    
    var callback: Callback
    
    init(_ callback: @escaping Callback) {
        self.callback = callback
    }
}

// MARK: - Private

private class P2PNetworkSessionListener {
    private var _peerDelegates = [WeakPeerDelegate]()
    private var _dataHandlers = [String: [Weak<DataHandler>]]()
    
    fileprivate func onReceiveData(eventName: String, _ handleData: @escaping DataHandler.Callback) -> DataHandler {
        let handler = DataHandler(handleData)
        if let handlers = _dataHandlers[eventName] {
            _dataHandlers[eventName] = handlers.filter { $0.weakRef != nil } + [Weak(handler)]
        } else {
            _dataHandlers[eventName] = [Weak(handler)]
        }
        return handler
    }
    
    fileprivate func addPeerDelegate(_ delegate: P2PNetworkPeerDelegate) {
        if !_peerDelegates.contains(where: { $0.delegate === delegate }) {
            _peerDelegates.append(WeakPeerDelegate(delegate))
        }
        _peerDelegates.removeAll(where: { $0.delegate == nil })
    }
    
    fileprivate func removePeerDelegate(_ delegate: P2PNetworkPeerDelegate) {
        _peerDelegates.removeAll(where: { $0.delegate === delegate || $0.delegate == nil })
    }
    
    fileprivate func notifyPeerDelegateOfHostUpdate(_ host: Peer?) {
        for peerDelegateWrapper in _peerDelegates {
            peerDelegateWrapper.delegate?.p2pNetwork(didUpdateHost: host)
        }
    }
}

extension P2PNetworkSessionListener: P2PSessionDelegate {
    func p2pSession(_ session: P2PSession, didUpdate peer: Peer) {
        guard !P2PNetwork.soloMode else { return }

        for peerDelegateWrapper in _peerDelegates {
            peerDelegateWrapper.delegate?.p2pNetwork(didUpdate: peer)
        }
    }
    
    func p2pSession(_ session: P2PSession, didReceive data: Data, dataAsJson json: [String : Any]?, from peerID: MCPeerID) {
        guard !P2PNetwork.soloMode else { return }
        
        if let eventName = json?["eventName"] as? String {
            if let handlers = _dataHandlers[eventName] {
                for handler in handlers {
                    handler.weakRef?.callback(data, json, peerID)
                }
            }
        }
        
        if let handlers = _dataHandlers[""] {
            for handler in handlers {
                handler.weakRef?.callback(data, json, peerID)
            }
        }
    }
}

private class WeakPeerDelegate {
    weak var delegate: P2PNetworkPeerDelegate?
    
    init(_ delegate: P2PNetworkPeerDelegate) {
        self.delegate = delegate
    }
}

private class Weak<T: AnyObject> {
    weak var weakRef: T?
    
    init(_ weakRef: T) {
        self.weakRef = weakRef
    }
}

