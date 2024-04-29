//
//  P2PNetworking.swift
//  P2PKitExample


import MultipeerConnectivity
import os.signpost

struct P2PConstants {
    static let networkChannelName = "my-p2p-service"
    static let loggerEnabled = true
}

protocol P2PNetworkSessionDelegate {
    func p2pNetworkSession(_ session: P2PNetworkSession, didUpdate player: Player) -> Void
    func p2pNetworkSession(_ session: P2PNetworkSession, didReceive: Data, from player: Player) -> Bool
}

private struct DiscoveryInfo {
    let startTime: TimeInterval
    
    func shouldInvite(_ otherInfo: DiscoveryInfo) -> Bool {
        return startTime < otherInfo.startTime
    }
}

class P2PNetworkSession: NSObject {
    
    static var shared = P2PNetworkSession()
    
    var delegates = [P2PNetworkSessionDelegate]() // TODO: Weak Ref?
    
    let myPlayer = UserDefaults.standard.myself
    let session: MCSession
    let advertiser: MCNearbyServiceAdvertiser
    let browser: MCNearbyServiceBrowser
    
    private let myDiscoveryInfo = DiscoveryInfo(startTime: Date().timeIntervalSince1970)
    
    private var playersLock = NSLock()
    private var sessionStates = [MCPeerID: MCSessionState]() // protected with playersLock
    private var discoveryInfos = [MCPeerID: DiscoveryInfo]() // protected with playersLock
    private var foundPeers = Set<MCPeerID>()  // protected with playersLock
    
    var connectedPeers: [Player] {
        prettyPrint(level: .debug, "\(session.connectedPeers)")
        return session.connectedPeers.filter { foundPeers.contains($0) }.map{ Player($0) }
    }
    
    override init() {
        let myPeerID = myPlayer.peerID
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID,
                                               discoveryInfo: ["startTime": "\(myDiscoveryInfo.startTime)"],
                                               serviceType: P2PConstants.networkChannelName)
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: P2PConstants.networkChannelName)
        
        super.init()
        
        session.delegate = self
        
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()

        browser.delegate = self
        browser.startBrowsingForPeers()
    }
    
    deinit {
        prettyPrint("Deinit")
        stopServices()
        session.disconnect()
        session.delegate = nil
    }
    
    private func stopServices() {
        advertiser.stopAdvertisingPeer()
        advertiser.delegate = nil
        
        browser.stopBrowsingForPeers()
        browser.delegate = nil
    }
    
    func connectionState(for peer: MCPeerID) -> MCSessionState? {
        playersLock.lock(); defer { playersLock.unlock() }
        return sessionStates[peer]
    }

    // MARK: - Sending
    
    func send(_ encodable: Encodable, to peers: [MCPeerID] = []) {
        do {
            let data = try JSONEncoder().encode(encodable)
            send(data: data, to: peers)
        } catch {
            prettyPrint(level: .error, "Could not encode: \(error.localizedDescription)")
        }
    }
    
    func send(data: Data, to peers: [MCPeerID] = []) {
        let sendToPeers = peers == [] ? session.connectedPeers : peers
        guard !sendToPeers.isEmpty else {
            return
        }
        
        do {
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            prettyPrint(level: .error, "error sending data to peers: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Delegates
    
    func addDelegate(_ delegate: P2PNetworkSessionDelegate) {
        delegates.append(delegate)
    }
    
    private func updateSessionDelegates(forPeer peerID: MCPeerID) {
        for delegate in delegates {
            delegate.p2pNetworkSession(self, didUpdate: Player(peerID))
        }
    }
    
    // MARK: - Loopback Test
    // Test whether a connection is still alive.
    
    private func startLoopbackTest(_ peerID: MCPeerID) {
        prettyPrint("Sending Ping to \(peerID.displayName)")
        send(["ping": ""], to: [peerID])
    }
    
    private func handleLoopbackTest(_ session: MCSession, didReceive json: [String: Any], fromPeer peerID: MCPeerID) -> Bool {
        if json["ping"] as? String == "" {
            prettyPrint("Sending Pong to \(peerID.displayName)")
            send(["pong": ""])
            return true
        } else if json["pong"] as? String == "" {
            prettyPrint("Received Pong from \(peerID.displayName)")
            playersLock.lock()
            if sessionStates[peerID] == nil {
                sessionStates[peerID] = .connected
            }
            playersLock.unlock()
            
            updateSessionDelegates(forPeer: peerID)
            return true
        }
        return false
    }
}

extension P2PNetworkSession: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        prettyPrint("Session state of [\(peerID.displayName)] changed to [\(state)]")
        
        playersLock.lock()
        sessionStates[peerID] = state
        playersLock.unlock()
        
        switch state {
        case .connected:
            playersLock.lock()
            if !foundPeers.contains(peerID) {
                foundPeers.insert(peerID)
            }
            playersLock.unlock()
        case .connecting:
            break
        case .notConnected:
            invitePeerIfNeeded(peerID)
        default:
            fatalError(#function + " - Unexpected multipeer connectivity state.")
        }
        
        updateSessionDelegates(forPeer: peerID)
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let json = try? JSONSerialization.jsonObject(with: data) {
            prettyPrint("Received: \(json)")
            
            if let json = json as? [String: Any] {
                if handleLoopbackTest(session, didReceive: json, fromPeer: peerID) {
                    return
                }
            }
        }
        
        for delegate in delegates {
            if delegate.p2pNetworkSession(self, didReceive: data, from: Player(peerID)) {
                return
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        fatalError("This service does not send/receive streams.")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        fatalError("This service does not send/receive resources.")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        fatalError("This service does not send/receive resources.")
    }
    
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
}

extension P2PNetworkSession: MCNearbyServiceBrowserDelegate {
    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        prettyPrint("Found peer: [\(peerID)]")
        
        playersLock.lock()
        if !foundPeers.contains(peerID) {
            foundPeers.insert(peerID)
        }
        playersLock.unlock()
        
        if let other = info?["startTime"], let otherStartTime = Double(other) {
            playersLock.lock()
            discoveryInfos[peerID] = DiscoveryInfo(startTime: otherStartTime)
            if sessionStates[peerID] == nil, session.connectedPeers.contains(peerID) {
                startLoopbackTest(peerID)
            }
            playersLock.unlock()
            
            invitePeerIfNeeded(peerID)
        }
        
        updateSessionDelegates(forPeer: peerID)
    }
    
    public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        prettyPrint("Lost peer: [\(peerID.displayName)]")
        
        playersLock.lock()
        if foundPeers.contains(peerID) {
            foundPeers.remove(peerID)
        }
        
        // When a peer enters background, session.connectedPeers still contains that peer.
        // Setting this to nil ensures we make a loopback test to test the connection.
        sessionStates[peerID] = nil
        
        playersLock.unlock()
        
        updateSessionDelegates(forPeer: peerID)
    }
    
    private func invitePeerIfNeeded(_ peerID: MCPeerID) {
        let info: DiscoveryInfo?
        let sessionState: MCSessionState?
        playersLock.lock()
        info = discoveryInfos[peerID]
        sessionState = sessionStates[peerID]
        playersLock.unlock()
        
        if let info = info, myDiscoveryInfo.startTime < info.startTime,
           !session.connectedPeers.contains(peerID), sessionState != .connecting {
            prettyPrint("Inviting peer: [\(peerID.displayName)]")
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 3)
        }
    }
}

extension P2PNetworkSession: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        prettyPrint("Accepting Peer invite from [\(peerID.displayName)]")
        invitationHandler(true, self.session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        prettyPrint(level:.error, "Error: \(error.localizedDescription)")
    }
}
