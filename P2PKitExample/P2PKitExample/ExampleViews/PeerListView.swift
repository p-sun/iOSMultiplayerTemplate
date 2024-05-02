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
    
    func changeName() {
        let randomAnimal = Array("🦊🐯🐹🐶🐸🐵🐮🦄🐷🐨🐼🐰🐻🐷🐨🐼🐰🐻").randomElement()!
        P2PNetwork.resetSession(displayName: "\(randomAnimal) \(UIDevice.current.name)")
    }
    
    func resetSession() {
        P2PNetwork.resetSession()
    }
}

extension PeerListViewModel: P2PNetworkSessionDelegate {
    func p2pNetworkSession(_ session: P2PNetworkSession, didReceive data: Data, dataAsJson json: [String : Any]?, from player: Player) -> Bool {
        return false
    }
    
    func p2pNetworkSession(_ session: P2PNetworkSession, didUpdate player: Player) {
        DispatchQueue.main.async { [weak self] in
            self?.playerList = session.connectedPeers
        }
    }
}

struct PeerListView: View {
    @StateObject var model = PeerListViewModel()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Current Device").p2pTitleStyle()
            Text(P2PNetwork.myPlayer.displayName).font(.largeTitle)
            HStack {
                Button("Change Name") {
                    model.changeName()
                }
                Button("Reset Session") {
                    model.resetSession()
                }
            }
            
            Text("Found Devices").p2pTitleStyle()
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
        .p2pButtonStyle()
    }
}

#Preview {
    PeerListView()
}
