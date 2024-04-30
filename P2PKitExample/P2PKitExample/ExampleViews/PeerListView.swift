//
//  PeerListView.swift
//  P2PKitExample
//
//  Created by Paige Sun on 4/24/24.
//

import SwiftUI

class PeerListViewModel: ObservableObject {
    @Published var playerList = [Player]()
    
    init() {
        P2PNetwork.addDelegate(self)
        P2PNetwork.start()
    }
    
    func resetNetwork() {
        playerList = []
        P2PNetwork.reset(displayName: "\(UIDevice.current.name) <<\(Int.random(in: 1...100))>>")
    }
    
    deinit {
        P2PNetwork.removeDelegate(self)
    }
}

extension PeerListViewModel: P2PNetworkSessionDelegate {
    func p2pNetworkSession(_ session: P2PNetworkSession, didUpdate player: Player) {
        DispatchQueue.main.async { [weak self] in
            self?.playerList = session.connectedPeers
        }
    }
    
    func p2pNetworkSession(_ session: P2PNetworkSession, didReceive: Data, from player: Player) -> Bool {
        return false
    }
}

struct PeerListView: View {
    @StateObject var model = PeerListViewModel()
    
    var body: some View {
        Group {
            Text("Current Device").font(.headline)
            Text(P2PNetwork.myPlayer.username)
            Button("Change Name") {
                model.resetNetwork()
            }
            Spacer().frame(height: 24)
            
            Text("Found Devices").font(.headline)
            VStack(alignment: .leading, spacing: 10) {
                if model.playerList.isEmpty {
                    ProgressView()
                } else {
                    ForEach(model.playerList, id: \.peerID) { peer in
                        let connectionState = P2PNetwork.connectionState(for: peer.peerID)
                        let connectionStateStr = connectionState != nil ? connectionState!.debugDescription : "No Session"
                        Text("\(peer.peerID.displayName): \(connectionStateStr)")
                    }
                }
            }
        }
    }
}

#Preview {
    PeerListView()
}
