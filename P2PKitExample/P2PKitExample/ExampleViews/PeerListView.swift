//
//  PeerListView.swift
//  P2PKitExample
//
//  Created by Paige Sun on 4/24/24.
//

import SwiftUI
import MultipeerConnectivity

class PeerListViewModel: ObservableObject {
    let p2pSession = P2PNetworkSession.shared
    @Published var playerList = [Player]()
    
    init() {
        p2pSession.addDelegate(self)
        p2pSession.start()
    }
}

extension PeerListViewModel: P2PNetworkSessionDelegate {
    func p2pNetworkSession(_ session: P2PNetworkSession, didUpdate player: Player) {
        DispatchQueue.main.async { [weak self] in
            self?.playerList = session.connectedPeers
        }
    }
    
    func p2pNetworkSession(_ session: P2PNetworkSession, didReceive: Data, from player: Player) {
    }
}

struct PeerListView: View {
    @StateObject var model = PeerListViewModel()
    
    @State var isPresented = false
    
    var body: some View {
        HStack() {
            VStack(alignment: .leading) {
                Text("Current Device:").font(.headline)
                Text(model.p2pSession.myPlayer.peerID.displayName)
                Spacer().frame(height: 24)
                
                Text("Found Devices:").font(.headline)
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(model.playerList, id: \.peerID) { peer in
                        let connectionState = model.p2pSession.connectionState(for: peer.peerID)
                        let connectionStateStr = connectionState != nil ? connectionState!.debugDescription : "No Session"
                        Text("\(peer.peerID.displayName) \n--- \(connectionStateStr)")
                    }
                }
                
                Spacer().frame(height: 20)
                Button("Open Browser") {
                    isPresented = true
                }.sheet(isPresented: $isPresented) {
                    BrowerView(brower: model.p2pSession.browser, session: model.p2pSession.session)
                }
                
                Spacer().frame(height: 20)
                Button("Send Test Event") {
                    let data = try! JSONEncoder().encode(["TEST EVENT": "from button!"])
                    model.p2pSession.send(data: data)
                }
            }
            Spacer()
        }
    }
}

#Preview {
    PeerListView()
}

fileprivate var browerViewDelegate = BrowerViewDelegate()

struct BrowerView: UIViewControllerRepresentable {
    typealias UIViewControllerType = MCBrowserViewController
    
    let brower: MCNearbyServiceBrowser
    let session: MCSession
    
    func makeUIViewController(context: Context) -> MCBrowserViewController {
        let controller = MCBrowserViewController(browser: brower, session: session)
        controller.delegate = browerViewDelegate
        return controller
    }
    
    func updateUIViewController(_ uiViewController: MCBrowserViewController, context: Context) {
    }
}

class BrowerViewDelegate: NSObject, MCBrowserViewControllerDelegate {
    override init() {
        super.init()
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true)
    }
}
