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

private struct PSMessageInfo: Codable {
    let name: String
    let sender: String
    let sendTime: Double
    
    init(name: String, sender: String) {
        self.name = name
        self.sender = sender
        self.sendTime = Date().timeIntervalSince1970
    }
}

class PSNetworking<T: Codable> {
    public lazy var myName: PeerName = {
        return peersController.myName
    }()
    
    private let peersController = PeersController.shared
    
    let name: String
    var listeners: [(T) -> Void] = []
    
    init(name: String) {
        self.name = name
        myName = peersController.myName
        peersController.peersDelegates.append(self)
    }

    func send(_ sendable: T) {
        let message = PSMessage(info: PSMessageInfo(name: name, sender: myName), sendable: sendable)
        peersController.sendMessage(message, viaStream: false)
    }
    
    func listen(_ callback: @escaping (T) -> Void) {
        listeners.append(callback)
    }
}

extension PSNetworking: PeersControllerDelegate {
    func sessionDidUpdate() {
    }
    
    public func received(data: Data, viaStream: Bool) -> Bool {
       if let message = try? JSONDecoder().decode(PSMessage<T>.self, from: data) {
            if message.info.sender != self.myName && message.info.name == name {
                for listener in listeners {
                   listener(message.sendable)
                }
                return true
            }
        }
        return false
    }
}
