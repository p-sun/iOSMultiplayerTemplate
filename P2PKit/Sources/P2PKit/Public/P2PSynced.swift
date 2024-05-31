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
    
    public init(name: String, initial: T, writeAccess: WriteAccess = .everyone) {
        self.synced = P2PSynced(name: name, initial: initial, writeAccess: writeAccess)
        self.synced.onReceiveSync = { [weak self] newVal in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }
    }
}

public enum WriteAccess {
    case hostOnly, everyone
}

// When any peer send values, all other peer will receive it.
// If isHost is set to true, this will sync the value from host when a new P2PSynced is created with the same eventName, or when the device with that P2PSynced reconnects.
public class P2PSynced<T: Codable> {
    public var value: T {
        get {
            _lock.lock(); defer { _lock.unlock() }
            return _value
        }
        set {
            sendValue(newValue, reliable: _reliable)
        }
    }
    
    public var onReceiveSync: ((T) -> Void)? = nil
    
    let eventName: String
    let syncID = UUID().uuidString
    
    private let _updateService: P2PEventService<T>
    private let _requestUpdateService: P2PEventService<String>
    private let _writeAccess: WriteAccess
    private let _reliable: Bool
    
    private let _lock = NSLock()
    private var _value: T
    private var _lastUpdated = TimeInterval(0)
    private var _host: Peer?
    
    deinit {
        P2PNetwork.removePeerDelegate(self)
    }
    
    public init(name: String, initial: T, writeAccess: WriteAccess, reliable: Bool = false) {
        self.eventName = name
        _updateService = P2PEventService<T>(name)
        _requestUpdateService = P2PEventService<String>(name + "-RequestUpdateFromHost")
        _value = initial
        _writeAccess = writeAccess
        _reliable = reliable
        
        P2PNetwork.addPeerDelegate(self)
        
        _updateService.onReceive { [weak self] (eventInfo: EventInfo, payload: T, json: [String: Any]?, sender: MCPeerID) in
            guard let self = self else { return }
            
            self._lock.lock()
            guard writeAccess == .everyone ||
                    writeAccess == .hostOnly && sender == self._host?.peerID else {
                self._lock.unlock()
                return
            }
            
            let shouldUpdate = self._lastUpdated < eventInfo.sendTime
            if shouldUpdate {
                self._value = payload
                self._lastUpdated = eventInfo.sendTime
            }
            self._lock.unlock()
            if shouldUpdate {
                self.onReceiveSync?(payload)
            }
        }
        
        _requestUpdateService.onReceive { [weak self] _, _, _, sender in
            guard let self = self else { return }
            
            _lock.lock()
            guard _host?.isMe == true else {
                _lock.unlock()
                return
            }
            _lock.unlock()
            sendValue(to: [sender], reliable: true)
        }
        
        if let host = P2PNetwork.host {
            p2pNetwork(didUpdateHost: host)
        }
    }
    
    // Set payload to nil to send current _value
    private func sendValue(_ newValue: T? = nil, to peers: [MCPeerID] = [], reliable: Bool) {
        _lock.lock()
        guard _writeAccess == .everyone ||
                _writeAccess == .hostOnly && _host?.isMe == true else {
            _lock.unlock()
            return
        }
        
        let sendTime = Date().timeIntervalSince1970
        if let newValue = newValue {
            _lastUpdated = sendTime
            _value = newValue
        }
        let playloadToSend = newValue ?? _value
        _lock.unlock()
        
        _updateService.send(payload: playloadToSend, senderID: syncID, sendTime: sendTime, to: peers, reliable: reliable)
    }
}

extension P2PSynced: P2PNetworkPeerDelegate {
    public func p2pNetwork(didUpdateHost host: Peer?) {
        _lock.lock()
        _host = host
        _lock.unlock()
        
        if host?.isMe == true {
            sendValue(reliable: true)
        } else if let host = host {
            _requestUpdateService.send(payload: "", senderID: syncID, to: [host.peerID], reliable: true)
        }
    }
    
    public func p2pNetwork(didUpdate peer: Peer) {
        // Intentionally empty because Peers must request for updates from host first, to ensure Peer is ready to receive data from to host.
    }
}
