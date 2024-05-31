//
//  P2PEventService.swift
//  P2PEventService sends and receive Data or Codable types.
//
//  Created by Paige Sun on 5/22/24.
//

import MultipeerConnectivity

public class P2PEventService<T: Codable> {
    private var _handlers = [DataHandler]()
    
    let eventName: String
    public init(_ eventName: String) {
        self.eventName = eventName
    }
    
    // Receive Data
    public func onReceiveData(callback: @escaping (_ data: Data, _ dataAsJson: [String: Any]?, _ sender: MCPeerID) -> Void) {
        let handler = P2PNetwork.onReceiveData(eventName: eventName, callback)
        _handlers.append(handler)
    }
    
    // Receive Codable Payload
    public func onReceive(callback: @escaping (_ eventInfo: EventInfo, _ payload: T, _ json: [String: Any]?, _ sender: MCPeerID) -> Void) {
        
        let castedHandler: DataHandler.Callback = { [eventName] (data, json, fromPeerID) in
            do {
                let event = try JSONDecoder().decode(Event<T>.self, from: data)
                if event.eventName == eventName {
                    callback(event.info, event.payload, json, fromPeerID)
                }
            } catch {
                fatalError("Could not decode event of type \(Event<T>.self).\nJSON: \(String(describing: json))")
            }
        }
        let handler = P2PNetwork.onReceiveData(eventName: eventName, castedHandler)
        _handlers.append(handler)
    }
    
    public func send(payload: T, senderID: String? = nil, sendTime: TimeInterval = Date().timeIntervalSince1970, to peers: [MCPeerID] = [], reliable: Bool) {
        let eventInfo = EventInfo(
            senderEntityID: senderID,
            sendTime: sendTime)
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
