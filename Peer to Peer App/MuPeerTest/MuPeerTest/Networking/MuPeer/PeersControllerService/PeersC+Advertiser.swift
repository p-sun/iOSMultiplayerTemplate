//  created by musesum on 12/8/22.


import MultipeerConnectivity

extension PeersController: MCNearbyServiceAdvertiserDelegate {

    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                           didReceiveInvitationFromPeer peerID: MCPeerID,
                           withContext _: Data?,
                           invitationHandler: @escaping (Bool, MCSession?) -> Void) {

        logPeer("didReceiveInvitationFromPeer:  \"\(peerID.displayName)\"")

        invitationHandler(true, session)
    }

    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                           didNotStartAdvertisingPeer error: Error) {

        logPeer("didNotStartAdvertisingPeer \(error)")
    }
}
