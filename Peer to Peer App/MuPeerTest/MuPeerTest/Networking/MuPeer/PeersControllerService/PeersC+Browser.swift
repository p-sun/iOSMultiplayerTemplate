//
//  PeersC+Browser.swift
//  MultiPeer
//
//  created by musesum on 12/8/22.
//

import MultipeerConnectivity

extension PeersController: MCNearbyServiceBrowserDelegate {

    // Found a nearby advertising peer
    public func browser(_ browser: MCNearbyServiceBrowser,
                        foundPeer peerID: MCPeerID,
                        withDiscoveryInfo info: [String : String]?) {
        let peerName = peerID.displayName
        logPeer("Browser found peer \"\(peerName)\" who is \(peerState[peerName] == .connected ? "connected" : "no connected")")
        let shouldInvite = myName != peerName
            && (peerState[peerName] == nil || peerState[peerName] != .connected)

        if shouldInvite {
            logPeer("Inviting \"\(peerName)\"")
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10.0)
        } else {
            logPeer("Not inviting \"\(peerName)\"")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self = self else { return }
            logPeer("Retrying invite \"\(peerName)\"")
            if self.peerState[peerName] != .connected {
                browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10.0)
            }
         }
    }

    public func browser(_ browser: MCNearbyServiceBrowser,
                        lostPeer peerID: MCPeerID) {
        let peerName = peerID.displayName
        logPeer("lostPeer: \"\(peerName)\"")
    }

    public func browser(_ browser: MCNearbyServiceBrowser,
                        didNotStartBrowsingForPeers error: Error) {

        logPeer("didNotStartBrowsingForPeers: \(error)")
    }
}
