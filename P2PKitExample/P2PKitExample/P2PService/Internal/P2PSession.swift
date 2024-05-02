//
//  P2PNetworking.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/2/24.
//

import MultipeerConnectivity

// MARK: - P2PSession

protocol P2PSessionDelegate: AnyObject {
    func p2pSession(_ session: P2PSession, didUpdate player: Player) -> Void
    func p2pSession(_ session: P2PSession, didReceive data: Data, dataAsJson json: [String: Any]?, from player: Player) -> Bool
}

class P2PSession: NSObject {
    var delegates: [P2PSessionDelegate] {
        get {
            return _delegates.compactMap { $0.delegate }
        }
    }
    
    private var _delegates = [WeakDelegate]()
    
    let myPlayer: Player
    private let myDiscoveryInfo = DiscoveryInfo()
    
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser
    private let browser: MCNearbyServiceBrowser
    
    private var peersLock = NSLock()
    private var foundPeers = Set<MCPeerID>()  // protected with peersLock
    private var discoveryInfos = [MCPeerID: DiscoveryInfo]() // protected with peersLock
    private var sessionStates = [MCPeerID: MCSessionState]() // protected with peersLock
    private var invitesHistory = [MCPeerID: InviteHistory]() // protected with peersLock
    
    var connectedPeers: [Player] {
        peersLock.lock(); defer { peersLock.unlock() }
        prettyPrint(level: .debug, "\(session.connectedPeers)")
        return session.connectedPeers.filter { foundPeers.contains($0) }.map { Player($0) }
    }
    
    init(myPlayer: Player) {
        self.myPlayer = myPlayer
        let myPeerID = myPlayer.peerID
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID,
                                               discoveryInfo: ["discoveryId": "\(myDiscoveryInfo.discoveryId)"],
                                               serviceType: P2PConstants.networkChannelName)
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: P2PConstants.networkChannelName)
        
        super.init()
        
        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self
    }
    
    func start() {
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
        updateSessionDelegates(forPeer: myPlayer.peerID)
    }
    
    deinit {
        disconnect()
    }
    
    func disconnect() {
        prettyPrint("disconnect")
        
        session.disconnect()
        session.delegate = nil
        
        advertiser.stopAdvertisingPeer()
        advertiser.delegate = nil
        
        browser.stopBrowsingForPeers()
        browser.delegate = nil
    }
    
    func connectionState(for peer: MCPeerID) -> MCSessionState? {
        peersLock.lock(); defer { peersLock.unlock() }
        return sessionStates[peer]
    }
    
    func makeBrowserViewController() -> MCBrowserViewController {
        return MCBrowserViewController(browser: browser, session: session)
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
    
    func addDelegate(_ delegate: P2PSessionDelegate) {
        if !_delegates.contains(where: { $0.delegate === delegate }) {
            _delegates.append(WeakDelegate(delegate))
        }
    }
    
    func removeDelegate(_ delegate: P2PSessionDelegate) {
        _delegates.removeAll(where: { $0.delegate === delegate || $0.delegate == nil })
    }
    
    private func updateSessionDelegates(forPeer peerID: MCPeerID) {
        for delegate in delegates {
            delegate.p2pSession(self, didUpdate: Player(peerID))
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
            prettyPrint("Received ping from \(peerID.displayName). Sending Pong.")
            send(["pong": ""], to: [peerID])
            return true
        } else if json["pong"] as? String == "" {
            prettyPrint("Received Pong from \(peerID.displayName)")
            peersLock.lock()
            if sessionStates[peerID] == nil {
                sessionStates[peerID] = .connected
            }
            peersLock.unlock()
            
            updateSessionDelegates(forPeer: peerID)
            return true
        }
        return false
    }
}

// MARK: - MCSessionDelegate

extension P2PSession: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        prettyPrint("Session state of [\(peerID.displayName)] changed to [\(state)]")
        
        peersLock.lock()
        sessionStates[peerID] = state
        
        switch state {
        case .connected:
            foundPeers.insert(peerID)
        case .connecting:
            break
        case .notConnected:
            invitePeerIfNeeded(peerID)
        default:
            fatalError(#function + " - Unexpected multipeer connectivity state.")
        }
        peersLock.unlock()
        
        updateSessionDelegates(forPeer: peerID)
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let json = json {
            if handleLoopbackTest(session, didReceive: json, fromPeer: peerID) {
                return
            } else {
                prettyPrint("Received: \(json)")
            }
        }
        
        for delegate in delegates {
            if delegate.p2pSession(self, didReceive: data, dataAsJson: json, from: Player(peerID)) {
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

// MARK: - Browser Delegate

extension P2PSession: MCNearbyServiceBrowserDelegate {
    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        if let discoveryId = info?["discoveryId"], discoveryId != myDiscoveryInfo.discoveryId {
            prettyPrint("Found peer: [\(peerID)]")
            
            peersLock.lock()
            foundPeers.insert(peerID)
            
            discoveryInfos[peerID] = DiscoveryInfo(discoveryId: discoveryId)
            if sessionStates[peerID] == nil, session.connectedPeers.contains(peerID) {
                startLoopbackTest(peerID)
            }
            
            invitePeerIfNeeded(peerID)
            peersLock.unlock()
            
            updateSessionDelegates(forPeer: peerID)
        }
    }
    
    public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        prettyPrint("Lost peer: [\(peerID.displayName)]")
        
        peersLock.lock()
        foundPeers.remove(peerID)
        
        // When a peer enters background, session.connectedPeers still contains that peer.
        // Setting this to nil ensures we make a loopback test to test the connection.
        sessionStates[peerID] = nil
        peersLock.unlock()
        
        updateSessionDelegates(forPeer: peerID)
    }
}

// MARK: - Advertiser Delegate

extension P2PSession: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        if isNotConnected(peerID) {
            prettyPrint("Accepting Peer invite from [\(peerID.displayName)]")
            invitationHandler(true, self.session)
        }
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        prettyPrint(level:.error, "Error: \(error.localizedDescription)")
    }
}

// MARK: - Private - Invite Peers

extension P2PSession {
    // Call this from inside a peerLock()
    private func invitePeerIfNeeded(_ peerID: MCPeerID) {
        func invitePeer(attempt: Int) {
            prettyPrint("Inviting peer: [\(peerID.displayName)]. Attempt \(attempt)")
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 6)
            invitesHistory[peerID] = InviteHistory(attempt: attempt, nextInviteAfter: Date().addingTimeInterval(retryWaitTime))
        }
        
        guard discoveryInfos[peerID]?.shouldBeInvited(by: myDiscoveryInfo) == true,
              isNotConnected(peerID) else {
            return
        }
        
        let retryWaitTime: TimeInterval = 1
        let maxRetries = 3
        
        if let prevInvite = invitesHistory[peerID] {
            if prevInvite.nextInviteAfter.timeIntervalSinceNow < -8 {
                // Waited long enough that we can restart attempt from 1.
                invitePeer(attempt: 1)
                
            } else if prevInvite.nextInviteAfter.timeIntervalSinceNow < 0 {
                // Waited long enough to do the next invite attempt.
                if prevInvite.attempt < maxRetries {
                    invitePeer(attempt: prevInvite.attempt + 1)
                } else {
                    prettyPrint(level: .error, "Max \(maxRetries) invite attempts reached for [\(peerID.displayName)].")
                }
                
            } else {
                if !prevInvite.nextInviteScheduled {
                    // Haven't waited long enough for next invite, so schedule the next invite.
                    prettyPrint("Inviting peer later: [\(peerID.displayName)] with attempt \(prevInvite.attempt + 1)")
                    
                    DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + retryWaitTime + 0.1) { [weak self] in
                        guard let self = self else { return }
                        self.peersLock.lock()
                        self.invitesHistory[peerID]?.nextInviteScheduled = false
                        self.invitePeerIfNeeded(peerID)
                        self.peersLock.unlock()
                    }
                    invitesHistory[peerID]?.nextInviteScheduled = true
                } else {
                    prettyPrint("No need to invite peer [\(peerID.displayName)]. Next invite is already scheduled.")
                }
            }
        } else {
            invitePeer(attempt: 1)
        }
    }
    
    private func isNotConnected(_ peerID: MCPeerID) -> Bool {
        return !session.connectedPeers.contains(peerID)
        && sessionStates[peerID] != .connecting
        && sessionStates[peerID] != .connected
    }
}

private struct InviteHistory {
    let attempt: Int
    let nextInviteAfter: Date
    var nextInviteScheduled: Bool = false
}

// MARK: - Private

private struct DiscoveryInfo {
    let discoveryId: String
    
    init(discoveryId: String? = nil) {
        // Ensure that between any pair of devices, only one invites.
        self.discoveryId = discoveryId ?? "\(UIDevice.current.identifierForVendor!)"
    }
    func shouldBeInvited(by myInfo: DiscoveryInfo) -> Bool {
        return myInfo.discoveryId < discoveryId
    }
}

private struct WeakDelegate {
    weak var delegate: P2PSessionDelegate?
    
    init(_ delegate: P2PSessionDelegate) {
        self.delegate = delegate
    }
}