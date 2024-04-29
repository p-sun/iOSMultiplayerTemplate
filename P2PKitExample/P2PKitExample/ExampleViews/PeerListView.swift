//
//  PeerListView.swift
//  P2PKitExample
//
//  Created by Paige Sun on 4/24/24.
//

import SwiftUI

class PeerListViewModel: ObservableObject {
    let p2pSession = P2PNetworkSession.shared
    
    @Published var playerList = [Player]()
    
    init() {
        p2pSession.addDelegate(self)
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
            Text(model.p2pSession.myPlayer.peerID.displayName)
            Spacer().frame(height: 24)
            
            Text("Found Devices").font(.headline)
            VStack(alignment: .leading, spacing: 10) {
                if model.playerList.isEmpty {
                    Text("No devices found")
                } else {
                    ForEach(model.playerList, id: \.peerID) { peer in
                        let connectionState = model.p2pSession.connectionState(for: peer.peerID)
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
