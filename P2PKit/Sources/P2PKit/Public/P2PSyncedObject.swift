//
//  P2PSyncedObject.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/3/24.
//

import Foundation

public class P2PSyncedObject<T: Codable>: ObservableObject {
    public var value: T {
        get {
            return val
        }
        set {
            send(newValue)
        }
    }
    
    private var val: T
    private let networking: P2PNetworkedEvent
    private var lastUpdated = Date().timeIntervalSince1970
    
    public init(name: String, initial: T) {
        prettyPrint("P2PSynced init: " + name)
        val = initial
        
        networking = P2PNetworkedEvent(eventName: name)
        networking.listen { (event: Event<T>, sender: Peer) in
            DispatchQueue.main.async { [weak self] in
                
                guard let self = self else { return }
                if lastUpdated < event.info.sendTime {
                    val = event.payload
                    lastUpdated = event.info.sendTime
                    objectWillChange.send()
                }
            }
        }
    }
    
    private func send(_ newValue: T) {
        let sendTime = networking.send(newValue).sendTime
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            lastUpdated = sendTime
            val = newValue
            objectWillChange.send()
        }
    }
}

private class P2PNetworkedEvent {
    private typealias DidReceiveData = (Data, [String : Any]?, Peer) -> Void

    let eventName: String
    let entityID = UUID().uuidString
    
    private var didReceiveData: DidReceiveData?
    
    init(eventName: String) {
        self.eventName = eventName
        P2PNetwork.addDataDelegate(self, forEventName: eventName)
    }
    
    func send<T: Codable>(_ payload: T) -> EventInfo {
        return P2PNetwork.sendEvent(eventName: eventName, payload: payload, senderID: entityID)
    }
    
    func listen<T: Codable>(_ callback: @escaping (_ event: Event<T>, _ sender: Peer) -> Void) {
        let castedCallback: DidReceiveData = { [weak self] (data, json, sender) in
            guard let self = self else { return }
            do {
                let event = try JSONDecoder().decode(Event<T>.self, from: data)
                if event.eventName == eventName {
                    callback(event, sender)
                }
            } catch {
                fatalError("Could not decode event of type \(Event<T>.self).\nJSON: \(String(describing: json))")
            }
        }
        didReceiveData = castedCallback
    }
}

extension P2PNetworkedEvent: P2PNetworkDataDelegate {
    func p2pNetwork(didReceive data: Data, dataAsJson json: [String : Any]?, from peer: Peer) -> Bool {
        return ((didReceiveData?(data, json, peer)) != nil) == true
    }
}
