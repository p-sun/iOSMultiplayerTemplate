//
//  P2PNetworkedEntity.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/3/24.
//

import Foundation

class P2PNetworkedEntity<T: Codable>: ObservableObject {
    var value: T {
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
    
    init(name: String, initial: T) {
        prettyPrint("P2PSynced init: " + name)
        val = initial
        
        networking = P2PNetworkedEvent(name: name)
        networking.listen(didReceiveEvent)
    }
    
    private func didReceiveEvent(event: Event<T>, sender: Player) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if lastUpdated < event.info.sendTime {
                val = event.payload
                lastUpdated = event.info.sendTime
                objectWillChange.send()
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
    private typealias DidReceiveData = (Data, [String : Any]?, Player) -> Void

    let eventName: String
    let senderEntityID = UUID().uuidString
    
    private var onChange: DidReceiveData?
    
    init(name: String) {
        self.eventName = name
        P2PNetwork.addDataDelegate(self, forEventName: name)
    }
    
    func send<T: Codable>(_ payload: T) -> EventInfo {
        return P2PNetwork.sendEvent(eventName: eventName, payload: payload, senderID: senderEntityID)
    }
    
    func listen<T: Codable>(_ callback: @escaping (_ event: Event<T>, _ sender: Player) -> Void) {
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
        onChange = castedCallback
    }
}

extension P2PNetworkedEvent: P2PNetworkDataDelegate {
    func p2pNetwork(didReceive data: Data, dataAsJson json: [String : Any]?, from player: Player) -> Bool {
        return ((onChange?(data, json, player)) != nil) == true
    }
}

struct Event<T: Codable>: Codable {
    let eventName: String
    let info: EventInfo
    let payload: T
}

struct EventInfo: Codable {
    let senderEntityID: String?
    let sendTime: Double
}
