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
    
    private let _eventService = P2PEventService<T>()
    private let _reliable: Bool
    
    private let lock = NSLock()
    private var _value: T
    private var _lastUpdated = Date().timeIntervalSince1970
    
    public init(name: String, initial: T, reliable: Bool = false) {
        self.eventName = name
        _value = initial
        _reliable = reliable
        
        _eventService.onReceive(eventName: eventName) { [weak self] (eventInfo: EventInfo, payload: T, json: [String: Any]?, sender: MCPeerID) in
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
        
        _eventService.send(eventName: eventName, payload: payload, senderID: syncID, to: [], reliable: _reliable)
    }
}

// P2PEventService sends and receive Data or Codable types.
public class P2PEventService<T: Codable> {
    private var handlers = [DataHandler]()
    
    public init() {
    }
    
    // Receive Data
    public func onReceiveData(eventName: String, callback: @escaping (_ data: Data, _ dataAsJson: [String: Any]?, _ sender: MCPeerID) -> Void) {
        let handler = P2PNetwork.onReceiveData(eventName: eventName, callback)
        handlers.append(handler)
    }
    
    // Receive Codable Payload
    public func onReceive(eventName: String, callback: @escaping (_ eventInfo: EventInfo, _ payload: T, _ json: [String: Any]?, _ sender: MCPeerID) -> Void) {
        
        let castedCallback: DataHandler.Callback = { (data, json, fromPeerID) in
            do {
                let event = try JSONDecoder().decode(Event<T>.self, from: data)
                if event.eventName == eventName {
                    callback(event.info, event.payload, json, fromPeerID)
                }
            } catch {
                fatalError("Could not decode event of type \(Event<T>.self).\nJSON: \(String(describing: json))")
            }
        }
        
        let handler = P2PNetwork.onReceiveData(eventName: eventName, castedCallback)
        handlers.append(handler)
    }
    
    public func send(eventName: String, payload: T, senderID: String, to peers: [MCPeerID] = [], reliable: Bool) {
        let eventInfo = EventInfo(
            senderEntityID: senderID,
            sendTime: Date().timeIntervalSince1970)
        P2PNetwork.send(Event(eventName: eventName,
                              info: eventInfo,
                              payload: payload),
                        to: peers,
                        reliable: reliable)
    }
}

private struct Event<T: Codable>: Codable {
    let eventName: String
    let info: EventInfo
    let payload: T
}
