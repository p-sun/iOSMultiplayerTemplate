//
//  P2PSynced.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/3/24.
//

import Foundation
import MultipeerConnectivity

public class P2PSyncedObject<T: Codable>: ObservableObject {
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
    
    private let synced: P2PSynced<T>
    
    public init(name: String, initial: T) {
        self.synced = P2PSynced(name: name, initial: initial)
        self.synced.onReceiveSync = { newVal in
            DispatchQueue.main.async { [weak self] in
                self?.objectWillChange.send()
            }
        }
    }
}

public class P2PSynced<T: Codable> {
    public var value: T {
        get {
            return _value
        }
        set {
            send(newValue)
        }
    }
    
    public var onReceiveSync: ((T) -> Void)? = nil
    
    let eventName: String
    let syncID = UUID().uuidString
    
    private let _network = P2PEventNetwork<T>()
    private let _reliable: Bool
    
    private let lock = NSLock()
    private var _value: T
    private var _lastUpdated = Date().timeIntervalSince1970
    
    public init(name: String, initial: T, reliable: Bool = false) {
        self.eventName = name
        _value = initial
        _reliable = reliable
        
        _network.onReceive(eventName: eventName) { [weak self] (eventInfo: EventInfo, payload: T, json: [String: Any]?, sender: MCPeerID) in
            guard let self = self else { return }
            lock.lock()
            if _lastUpdated < eventInfo.sendTime {
                _value = payload
                _lastUpdated = eventInfo.sendTime
            }
            lock.unlock()
            
            onReceiveSync?(payload)
        }
    }
    
    private func send(_ payload: T) {
        let sendTime = Date().timeIntervalSince1970
        lock.lock()
        _lastUpdated = sendTime
        _value = payload
        lock.unlock()
        
        P2PNetwork.send(eventName: eventName, payload: payload, senderID: syncID, sendTime: sendTime, reliable: _reliable)
    }
}

public class P2PEventNetwork<T: Codable> {
    private var handlers = [OnReceivedHandler]()
    
    public init() {}
    
    public func onReceive(eventName: String, callback: @escaping (_ eventInfo: EventInfo, _ payload: T, _ json: [String: Any]?, _ sender: MCPeerID) -> Void) {
        handlers.append(P2PNetwork.onReceive(eventName: eventName, callback))
    }
    
    public func send(eventName: String, payload: T, senderID: String, to peers: [MCPeerID] = [], reliable: Bool) {
        P2PNetwork.send(eventName: eventName, payload: payload, senderID: senderID, reliable: reliable)
    }
}
