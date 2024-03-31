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

protocol PSSendable: Codable {
    var sender: String { get }
    var timeSince1970: Double {get }
}

class PSNetworking<Sendable: PSSendable>: ObservableObject {

    public lazy var myName: PeerName = {
        return peersController.myName
    }()
    
    private let peersController = PeersController.shared
    
    private var cancellables = Set<AnyCancellable>()

    @Published var entity: Sendable {
        didSet {
            send(entity)
        }
    }
    
    init(defaultSendable: Sendable) {
        self.entity = defaultSendable
        
        myName = peersController.myName
        peersController.peersDelegates.append(self)
    }

    func send(_ sendable: Sendable) {
        if sendable.sender == myName {
            peersController.sendMessage(sendable, viaStream: false)
        }
    }
    
    func listen(_ callback: @escaping (Sendable) -> Void) {
        $entity.sink { [weak self] recievedSendable in
            if let self = self, recievedSendable.sender != myName {
                callback(recievedSendable)
            }
        }.store(in: &cancellables)
    }
}

extension PSNetworking: PeersControllerDelegate {
    public func received(data: Data, viaStream: Bool) -> Bool {
       if let receivedEntity = try? JSONDecoder().decode(Sendable.self, from: data) {
           Task {
               await MainActor.run {
                   if receivedEntity.sender != myName {
                       entity = receivedEntity
                   }
               }
           }
            return true
        }
        return false
    }

}
