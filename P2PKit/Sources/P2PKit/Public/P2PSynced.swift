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
            send(newValue)
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
    private var _lastUpdated = Date().timeIntervalSince1970
    
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
            
            if self._lastUpdated < eventInfo.sendTime {
                self._value = payload
                self._lastUpdated = eventInfo.sendTime
            }
            self._lock.unlock()
            self.onReceiveSync?(payload)
        }
        
        _requestUpdateService.onReceive { [weak self] _, _, _, sender in
            guard let self = self else { return }
            
            _lock.lock()
            guard _host?.isMe == true else {
                _lock.unlock()
                return
            }
            let payload = _value
            _lock.unlock()
            send(payload, to: [sender])
        }
        
        if let host = P2PNetwork.host {
            p2pNetwork(didUpdateHost: host)
        }
    }
        
    private func send(_ payload: T, to peers: [MCPeerID] = []) {
        _lock.lock()
        guard _writeAccess == .everyone ||
                _writeAccess == .hostOnly && _host?.isMe == true else {
            _lock.unlock()
            return
        }
        
        let sendTime = Date().timeIntervalSince1970
        _lastUpdated = sendTime
        _value = payload
        _lock.unlock()
        
        _updateService.send(payload: payload, senderID: syncID, to: peers, reliable: _reliable)
    }
}

extension P2PSynced: P2PNetworkPeerDelegate {
    public func p2pNetwork(didUpdateHost host: Peer?) {
        _lock.lock()
        _host = host
        let value = _value
        _lock.unlock()

        if host?.isMe == true {
            send(value)
        } else if let host = host {
            _requestUpdateService.send(payload: "", senderID: syncID, to: [host.peerID], reliable: _reliable)
        }
    }
    
    public func p2pNetwork(didUpdate peer: Peer) {
    }
}
