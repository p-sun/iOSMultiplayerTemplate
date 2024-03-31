//
//  Networking.swift
//  MuPeerTest
//
//  Created by Paige Sun on 3/30/24.
//

import Combine
import Foundation

class Weather {
    @Published var temperature: Double
    init(temperature: Double) {
        self.temperature = temperature
    }
}

class PlayerNetworking<Sendable: NetworkedEntity>: ObservableObject {
    let playerId: String

    private let peersController = PeersController.shared
    
    private var cancellables = Set<AnyCancellable>()

    @Published var entity: Sendable {
        didSet {
            send(entity)
        }
    }
    
    init(defaultSendable: Sendable) {
        self.entity = defaultSendable
        
        playerId = peersController.myName
        peersController.peersDelegates.append(self)
    }

    func send(_ sendable: Sendable) {
        if sendable.sender == playerId {
            peersController.sendMessage(sendable, viaStream: false)
        }
    }
    
    func listen(_ callback: @escaping (Sendable) -> Void) {
        $entity.sink { [weak self] recievedSendable in
            if let self = self, recievedSendable.sender != playerId {
                callback(recievedSendable)
            }
        }.store(in: &cancellables)
    }
}

extension PlayerNetworking: PeersControllerDelegate {
    public func received(data: Data, viaStream: Bool) -> Bool {
       if let receivedEntity = try? JSONDecoder().decode(Sendable.self, from: data) {
            if receivedEntity.sender != playerId {
                entity = receivedEntity
            }
            return true
        }
        return false
    }

}
