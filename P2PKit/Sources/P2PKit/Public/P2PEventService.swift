//
//  P2PEventService.swift
//  P2PEventService sends and receive Data or Codable types.
//
//  Created by Paige Sun on 5/22/24.
//

import MultipeerConnectivity

public class P2PEventService<T: Codable> {
    private var _handlers = [DataHandler]()
    
    public init() {}
    
    // Receive Data
    public func onReceiveData(eventName: String, callback: @escaping (_ data: Data, _ dataAsJson: [String: Any]?, _ sender: MCPeerID) -> Void) {
        let handler = P2PNetwork.onReceiveData(eventName: eventName, callback)
        _handlers.append(handler)
    }
    
    // Receive Codable Payload
    public func onReceive(eventName: String, callback: @escaping (_ eventInfo: EventInfo, _ payload: T, _ json: [String: Any]?, _ sender: MCPeerID) -> Void) {
        
        let castedHandler: DataHandler.Callback = { (data, json, fromPeerID) in
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
