//
//  PSNetworking.swift
//  MuPeerTest
//
//  Created by Paige Sun on 3/30/24.
//

import Combine
import Foundation

/**
 Make sure to add in Info.list:
     Bonjour Services
        _deepmuse_tcp
        _deepmuse._udp
     NSLocalNetworkUsageDescription
        This application will use local networking to discover nearby device (or whatever you'd like)
 
 Every device in the same room should be able to see each other, whether they're on bluetooth or wifi.
 */

public let PSChannelName = "deepmuse"

private struct PSMessage<T: Codable>: Codable {
    let info: PSMessageInfo
    let sendable: T
}

struct PSMessageInfo: Codable {
    let name: String
    let sender: String
    let sendTime: Double
    
    init(name: String, sender: String) {
        self.name = name
        self.sender = sender
        self.sendTime = Date().timeIntervalSince1970
    }
}

class PSNetworkingObservable<T: Codable>: ObservableObject {
    @Published private (set) var value: T
    private let networking: PSNetworking<T>
    private var lastUpdated = Date().timeIntervalSince1970
    
    init(name: String, initial: T) {
        networking = PSNetworking(name: name)
        value = initial
        
        networking.listen { [weak self] newValue, info in
            guard let self = self else { return }
            if lastUpdated < info.sendTime {
                value = newValue
                lastUpdated = info.sendTime
            }
        }
    }
    
    func send(_ sendable: T) {
        value = sendable
        lastUpdated = networking.send(sendable).sendTime
    }
}


class PSNetworking<T: Codable> {
    let name: String

    public lazy var myName: PeerName = {
        return peersController.myName
    }()
    
    private let peersController = PeersController.shared
    private var callbacks: [(T, PSMessageInfo) -> Void] = []
    
    init(name: String) {
        self.name = name
        myName = peersController.myName
        peersController.peersDelegates.append(self)
    }

    @discardableResult
    func send(_ sendable: T) -> PSMessageInfo {
        let info = PSMessageInfo(name: name, sender: myName)
        let message = PSMessage(info: info, sendable: sendable)
        peersController.sendMessage(message, viaStream: false)
        return info
    }
    
    func listen(_ callback: @escaping (T, PSMessageInfo) -> Void) {
        callbacks.append(callback)
    }
}

extension PSNetworking: PeersControllerDelegate {
    func sessionDidUpdate() {
    }
    
    public func received(data: Data, viaStream: Bool) -> Bool {
       if let message = try? JSONDecoder().decode(PSMessage<T>.self, from: data) {
            if message.info.sender != self.myName && message.info.name == name {
                for callback in callbacks {
                    callback(message.sendable, message.info)
                }
                return true
            }
        }
        return false
    }
}
