//
//  GameLobbyView.swift
//  P2PKitDemo
//
//  Created by Paige Sun on 5/23/24.
//

import SwiftUI
import P2PKit

struct LobbyView: View {
    @StateObject var connected: ConnectedPeers
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 10) {
                Text("Me").p2pTitleStyle()
                Text("\(peerSummaryText(P2PNetwork.myPeer))")
                
                if connected.peers.isEmpty {
                    Text("Searching for Players...").p2pTitleStyle()
                    ProgressView()
                } else {
                    Text("Connected Players").p2pTitleStyle()
                    ForEach(connected.peers, id: \.peerID) { peer in
                        Text(peerSummaryText(peer))
                    }
                }
            }
            
            Spacer()
            if connected.host == nil && connected.peers.count > 0 {
                button("Create Room") {
                    P2PNetwork.makeMeHost()
                }
                Spacer().frame(height: 18)
            }
            
            button("Play Solo") {
                P2PNetwork.soloMode = true
                P2PNetwork.makeMeHost()
            }
        }
        .safeAreaPadding()
        .padding(EdgeInsets(top: 130, leading: 20,
                            bottom: 100, trailing: 20))
    }
    
    private func button(_ text: String, action: @escaping () -> Void) -> some View {
        Button(action: action, label: {
            Text(text).padding(10).font(.title)
        }).p2pButtonStyle()
    }
    
    private func peerSummaryText(_ peer: Peer) -> String {
        let isHostString = connected.host?.peerID == peer.peerID ? " ⭐️HOST⭐️" : ""
        return peer.displayName + isHostString
    }
}

class ConnectedPeers: ObservableObject {
    @Published var peers = [Peer]()
    @Published var host: Peer? = nil
    
    init() {
        P2PNetwork.addPeerDelegate(self)
        p2pNetwork(didUpdate: P2PNetwork.myPeer)
    }
    
    deinit {
        P2PNetwork.removePeerDelegate(self)
    }
}

extension ConnectedPeers: P2PNetworkPeerDelegate {
    func p2pNetwork(didUpdateHost host: Peer?) {
        DispatchQueue.main.async { [weak self] in
            self?.host = host
        }
    }
    
    func p2pNetwork(didUpdate peer: Peer) {
        DispatchQueue.main.async { [weak self] in
            self?.peers = P2PNetwork.connectedPeers
        }
    }
}
