//
//  P2PNetworking.swift
//  P2PKitExample


import MultipeerConnectivity
import os.signpost

struct P2PConstants {
    static let networkChannelName = "my-p2p-service"
    static let loggerEnabled = true
    
    struct UserDefaultsKeys {
        static let myPlayer = "MyPlayerIDKey"
    }
}

class P2PNetwork {
    private static var networkSession = P2PNetworkSession(myPlayer: UserDefaults.standard.myPlayer)
    
    static var myPlayer: Player {
        return networkSession.myPlayer
    }
    
    static func start() {
        networkSession.start()
    }
    
    static func send(_ encodable: Encodable, to peers: [MCPeerID] = []) {
        networkSession.send(encodable, to: peers)
    }
    
    static func send(data: Data, to peers: [MCPeerID] = []) {
        networkSession.send(data: data, to: peers)
    }
    
    static func addDelegate(_ delegate: P2PNetworkSessionDelegate) {
        networkSession.addDelegate(delegate)
    }
    
    static func removeDelegate(_ delegate: P2PNetworkSessionDelegate) {
        networkSession.removeDelegate(delegate)
    }
    
    static func connectionState(for peer: MCPeerID) -> MCSessionState? {
        networkSession.connectionState(for: peer)
    }
    
    static func resetSession(displayName: String? = nil) {
        let oldSession = networkSession
        oldSession.disconnect()
        
        let newPeerId = MCPeerID(displayName: displayName ?? oldSession.myPlayer.displayName)
        let myPlayer = Player(newPeerId)
        UserDefaults.standard.myPlayer = myPlayer
        
        networkSession = P2PNetworkSession(myPlayer: myPlayer)
        for delegate in oldSession.delegates {
            oldSession.removeDelegate(delegate)
            networkSession.addDelegate(delegate)
        }
        
        networkSession.start()
    }
    
    static func makeBrowserViewController() -> MCBrowserViewController {
        return networkSession.makeBrowserViewController()
    }
}

protocol P2PNetworkSessionDelegate: AnyObject {
    func p2pNetworkSession(_ session: P2PNetworkSession, didUpdate player: Player) -> Void
    func p2pNetworkSession(_ session: P2PNetworkSession, didReceive data: Data, dataAsJson json: [String: Any]?, from player: Player) -> Bool
}

class P2PNetworkSession: NSObject {
    var delegates: [P2PNetworkSessionDelegate] {
        get {
            return _delegates.compactMap { $0.delegate }
        }
    }
    
    private var _delegates = [WeakDelegate]()
    
    let myPlayer: Player
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser
    private let browser: MCNearbyServiceBrowser
    
    private let myDiscoveryInfo = DiscoveryInfo()
    
    private var peersLock = NSLock()
    private var foundPeers = Set<MCPeerID>()  // protected with playersLock
    private var discoveryInfos = [MCPeerID: DiscoveryInfo]() // protected with playersLock
    private var sessionStates = [MCPeerID: MCSessionState]() // protected with playersLock
    private var inviteAttempts = [MCPeerID: Int]() // protected with playersLock
    
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
    
    func addDelegate(_ delegate: P2PNetworkSessionDelegate) {
        if !_delegates.contains(where: { $0.delegate === delegate }) {
            _delegates.append(WeakDelegate(delegate))
        }
    }
    
    func removeDelegate(_ delegate: P2PNetworkSessionDelegate) {
        _delegates.removeAll(where: { $0.delegate === delegate || $0.delegate == nil })
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

extension P2PNetworkSession: MCSessionDelegate {
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
            prettyPrint("Received: \(json)")
            if handleLoopbackTest(session, didReceive: json, fromPeer: peerID) {
                return
            }
        }
        
        for delegate in delegates {
            if delegate.p2pNetworkSession(self, didReceive: data, dataAsJson: json, from: Player(peerID)) {
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

// MARK: - MCNearbyServiceBrowserDelegate

extension P2PNetworkSession: MCNearbyServiceBrowserDelegate {
    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        prettyPrint("Found peer: [\(peerID)]")
        
        if let discoveryId = info?["discoveryId"] {
            peersLock.lock()
            foundPeers.insert(peerID)
            
            discoveryInfos[peerID] = DiscoveryInfo(discoveryId: discoveryId)
            if sessionStates[peerID] == nil, session.connectedPeers.contains(peerID) {
                startLoopbackTest(peerID)
            }
            
            invitePeerIfNeeded(peerID)
            peersLock.unlock()
        }
        
        updateSessionDelegates(forPeer: peerID)
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
    
    private func invitePeerIfNeeded(_ peerID: MCPeerID) {
        if let peerInfo = discoveryInfos[peerID], myDiscoveryInfo.shouldInvite(peerInfo),
           !session.connectedPeers.contains(peerID),
           sessionStates[peerID] != .connecting, sessionStates[peerID] != .connected {
            
            let attempts = inviteAttempts[peerID] ?? 0
            inviteAttempts[peerID] = attempts + 1
            if attempts < 3 {
                prettyPrint("Inviting peer: [\(peerID.displayName)]")
                self.browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 6)
            }
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 6.1, execute: { [weak self] in
                guard let self = self else { return }
                if session.connectedPeers.contains(peerID) {
                    peersLock.lock()
                    inviteAttempts[peerID] = nil
                    peersLock.unlock()
                }
            })
        }
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension P2PNetworkSession: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        if !session.connectedPeers.contains(peerID),
           sessionStates[peerID] != .connecting, sessionStates[peerID] != .connected {
            prettyPrint("Accepting Peer invite from [\(peerID.displayName)]")
            invitationHandler(true, self.session)
        }
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        prettyPrint(level:.error, "Error: \(error.localizedDescription)")
    }
}

// MARK: - Private

private struct DiscoveryInfo {
    let discoveryId: String
    
    init(discoveryId: String? = nil) {
        self.discoveryId = discoveryId ?? "\(Date().timeIntervalSince1970) \(UUID().uuidString)"
    }
    
    func shouldInvite(_ otherInfo: DiscoveryInfo) -> Bool {
        return discoveryId < otherInfo.discoveryId
    }
}

private struct WeakDelegate {
    weak var delegate: P2PNetworkSessionDelegate?
    
    init(_ delegate: P2PNetworkSessionDelegate) {
        self.delegate = delegate
    }
}
