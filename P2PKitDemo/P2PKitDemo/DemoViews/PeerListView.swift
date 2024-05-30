//
//  PeerListView.swift
//  P2PKitExample
//
//  Created by Paige Sun on 4/24/24.
//

import SwiftUI
import P2PKit

class PeerListViewModel: ObservableObject {
    @Published var peerList = [Peer]()
    @Published var host: Peer? = nil
        
    init() {
        P2PNetwork.addPeerDelegate(self)
        p2pNetwork(didUpdate: P2PNetwork.myPeer)
        p2pNetwork(didUpdateHost: P2PNetwork.host)
    }
    
    deinit {
        P2PNetwork.removePeerDelegate(self)
    }
    
    func changeName() {
        let randomAnimal = Array("🦊🐯🐹🐶🐸🐵🐮🦄🐷🐰🐻").randomElement()!
        P2PNetwork.resetSession(displayName: "\(randomAnimal) \(UIDevice.current.name)")
    }
    
    func resetSession() {
        P2PNetwork.resetSession(displayName: newDisplayName(from: P2PNetwork.myPeer.displayName))
    }
    
    // oldName: "My iPhone <<7>>"
    // return: "My iPhone <<8>>"
    private func newDisplayName(from oldName: String) -> String {
        if let result = try? /\s<<(\d+)>>/.firstMatch(in: oldName), let count = Int(result.1)  {
            return oldName.replacing(/\s<<(\d+)>>/, with: "") + " <<\(count + 1)>>"
        } else {
            return oldName + " <<1>>"
        }
    }
}

extension PeerListViewModel: P2PNetworkPeerDelegate {
    func p2pNetwork(didUpdateHost host: Peer?) {
        DispatchQueue.main.async { [weak self] in
            self?.host = host
        }
    }
    
    func p2pNetwork(didUpdate peer: Peer) {
        DispatchQueue.main.async { [weak self] in
            self?.peerList = P2PNetwork.allPeers
        }
    }
}

struct PeerListView: View {
    @StateObject var model = PeerListViewModel()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Current Device").p2pTitleStyle()
            Text(peerSummaryText(P2PNetwork.myPeer))
            HStack {
                Button("Change Name") {
                    model.changeName()
                }
                Button("Reset Session") {
                    model.resetSession()
                }
            }.p2pSecondaryButtonStyle()

            Button("Make Me Host ⭐️") {
                P2PNetwork.makeMeHost()
            }.p2pSecondaryButtonStyle()

            Text("Found Devices").p2pTitleStyle()
            VStack(alignment: .leading, spacing: 10) {
                if model.peerList.isEmpty {
                    ProgressView()
                } else {
                    ForEach(model.peerList, id: \.peerID) { peer in
                        let connectionState = P2PNetwork.connectionState(for: peer.peerID)
                        let connectionStateStr = connectionState != nil ? connectionState!.debugDescription : "No Session"
                        Text("\(peerSummaryText(peer)): \(connectionStateStr)")
                    }
                }
            }
        }
    }
    
    private func peerSummaryText(_ peer: Peer) -> String {
        let isHostString = model.host?.peerID == peer.peerID ? " ⭐️" : ""
        return peer.displayName + isHostString
    }
}

#Preview {
    PeerListView()
}
