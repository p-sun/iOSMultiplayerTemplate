//
//  P2PSynced.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/3/24.
//

import Foundation
import MultipeerConnectivity

public class P2PSyncedObservable<T: Codable>: ObservableObject {
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
        self.synced.onReceiveSync = { [weak self] newVal in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }
    }
}

// When any peer send values, all other peer will receive it.
// If isHost is set to true, this will sync the value from host when a new P2PSynced is created with the same eventName, or when the device with that P2PSynced reconnects.
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
    
    private let _updateService: P2PEventService<T>
    private let _requestUpdateService: P2PEventService<String>
    private let _reliable: Bool
    
    private let _lock = NSLock()
    private var _value: T
    private var _lastUpdated = Date().timeIntervalSince1970

    private var _isHost: Bool = false

    deinit {
        P2PNetwork.removePeerDelegate(self)
    }
    
    public init(name: String, initial: T, reliable: Bool = false) {
        self.eventName = name
        _updateService = P2PEventService<T>(name)
        _requestUpdateService = P2PEventService<String>(name + "-RequestUpdateFromHost")
        _value = initial
        _reliable = reliable

        P2PNetwork.addPeerDelegate(self)
        
        _updateService.onReceive { [weak self] (eventInfo: EventInfo, payload: T, json: [String: Any]?, sender: MCPeerID) in
            guard let self = self else { return }
            self._lock.lock()
            if self._lastUpdated < eventInfo.sendTime {
                self._value = payload
                self._lastUpdated = eventInfo.sendTime
            }
            self._lock.unlock()
            self.onReceiveSync?(payload)
        }
        
        _requestUpdateService.onReceive { [weak self] _, _, _, sender in
            guard let self = self, self._isHost else { return }
            self._lock.lock()
            let payload = self._value
            self._lock.unlock()
            send(payload, to: [sender])
        }
        
        if let host = P2PNetwork.host {
            p2pNetwork(didUpdateHost: host)
        }
    }
    
    private func send(_ payload: T, to peers: [MCPeerID] = []) {
        let sendTime = Date().timeIntervalSince1970
        _lock.lock()
        _lastUpdated = sendTime
        _value = payload
        _lock.unlock()
        
        _updateService.send(payload: payload, senderID: syncID, to: peers, reliable: _reliable)
    }
}

extension P2PSynced: P2PNetworkPeerDelegate {
    public func p2pNetwork(didUpdateHost host: Peer?) {
        let isHost = host?.isMe == true
        _isHost = isHost
        
        if isHost {
            send(value)
        } else if !isHost, let host = host {
            _requestUpdateService.send(payload: "", senderID: syncID, to: [host.peerID], reliable: _reliable)
        }
    }
    
    public func p2pNetwork(didUpdate peer: Peer) {
    }
}
