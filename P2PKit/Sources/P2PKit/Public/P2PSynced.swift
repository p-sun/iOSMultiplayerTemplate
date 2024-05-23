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
    
    private let _eventService = P2PEventService<T>()
    private let _reliable: Bool
    
    private let _lock = NSLock()
    private var _value: T
    private var _lastUpdated = Date().timeIntervalSince1970
    
    public init(name: String, initial: T, reliable: Bool = false) {
        self.eventName = name
        _value = initial
        _reliable = reliable
        
        _eventService.onReceive(eventName: eventName) { [weak self] (eventInfo: EventInfo, payload: T, json: [String: Any]?, sender: MCPeerID) in
            guard let self = self else { return }
            self._lock.lock()
            if self._lastUpdated < eventInfo.sendTime {
                self._value = payload
                self._lastUpdated = eventInfo.sendTime
            }
            self._lock.unlock()
            
            self.onReceiveSync?(payload)
        }
    }
    
    private func send(_ payload: T) {
        let sendTime = Date().timeIntervalSince1970
        _lock.lock()
        _lastUpdated = sendTime
        _value = payload
        _lock.unlock()
        
        _eventService.send(eventName: eventName, payload: payload, senderID: syncID, to: [], reliable: _reliable)
    }
}
