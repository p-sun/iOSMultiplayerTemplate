//
//  P2PSynced.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/3/24.
//

import Foundation
import MultipeerConnectivity

public class P2PSynced<T: Codable>: ObservableObject {
    public var value: T {
        get {
            return synced.value
        }
        set {
            synced.value = newValue
            DispatchQueue.main.async { [weak self] in
                self?.objectWillChange.send()
            }
        }
    }
    
    private let synced: P2PSynced_<T>
    
    public init(name: String, initial: T) {
        self.synced = P2PSynced_(name: name, initial: initial)
        self.synced.didChange = { newVal in
            DispatchQueue.main.async { [weak self] in
                self?.objectWillChange.send()
            }
        }
    }
}

public class P2PSynced_<T: Codable> {
    public var value: T {
        get {
            return _value
        }
        set {
            send(newValue)
        }
    }
    
    let eventName: String
    let syncID = UUID().uuidString
    public var didChange: ((T) -> Void)? = nil
    
    private var _value: T
    private let _network = P2PEventNetwork<T>()
    private var _lastUpdated = Date().timeIntervalSince1970
    
    public init(name: String, initial: T) {
        self.eventName = name
        _value = initial
        
        _network.onReceive(eventName: eventName) { [weak self] (eventInfo: EventInfo, payload: T, json: [String: Any]?, sender: Peer) in
            guard let self = self else { return }
            if _lastUpdated < eventInfo.sendTime {
                _value = payload
                _lastUpdated = eventInfo.sendTime
                didChange?(payload)
            }
        }
    }
    
    private func send(_ payload: T) {
        let sendTime = P2PNetwork.send(eventName: eventName, payload: payload, senderID: syncID).sendTime
        _lastUpdated = sendTime
        _value = payload
    }
}

private class P2PEventNetwork<T: Codable> {
    private var handlers = [OnReceivedHandler]()
    
    public func onReceive(eventName: String, callback: @escaping (_ eventInfo: EventInfo, _ payload: T, _ json: [String: Any]?, _ sender: Peer) -> Void) {
        handlers.append(P2PNetwork.onReceive(eventName: eventName, callback))
    }
    
    public func send(eventName: String, payload: T, senderID: String, to peers: [MCPeerID] = []) -> EventInfo {
        return P2PNetwork.send(eventName: eventName, payload: payload, senderID: senderID)
    }
}