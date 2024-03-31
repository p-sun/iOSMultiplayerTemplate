//
//  PSNetworking.swift
//  MuPeerTest
//
//  Created by Paige Sun on 3/30/24.
//

import Combine
import Foundation

protocol PSNetworkable: Codable {
    var sender: String { get }
    var timeSince1970: Double {get }
}

class PSNetworking<Sendable: PSNetworkable>: ObservableObject {

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
            if receivedEntity.sender != myName {
                entity = receivedEntity
            }
            return true
        }
        return false
    }

}
