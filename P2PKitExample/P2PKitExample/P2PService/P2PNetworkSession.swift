//
//  P2PNetworking.swift
//  P2PKitExample

/**
 Make sure to add in Info.list:
    NSBonjourServices
        _my-p2p-service._tcp
        _my-p2p-service._udp
    NSLocalNetworkUsageDescription
        This application will use local networking to discover nearby devices. (Or your own custom message)
 
 Every device in the same room should be able to see each other, whether they're on bluetooth or wifi.
 */

import MultipeerConnectivity
import os.signpost

struct P2PConstants {
    static let networkChannelName = "my-p2p-service"
}

protocol P2PNetworkSessionDelegate {
    func p2pNetworkSession(_ session: P2PNetworkSession, didUpdate player: Player) -> Void
    func p2pNetworkSession(_ session: P2PNetworkSession, didReceive: Data, from player: Player) -> Void
}

struct WeakRef<T: AnyObject> {
  weak var value : T?
  init (value: T) {
    self.value = value
  }
}

/**
            Discovery Phase
 A      init               sees B      ... wait 1s ...->  "A is host" -> A sends invite
 B          init        sees A        ... wait 1s ...->  "A is host"            B accepts invite
 
 Disconnection
 A                                                                              [Found B] -> A sends invite
 [B backgrounds/kills app]      [B foregrounds]       ->  same as discovery phase
 
 Invitation Phase
 */

class P2PNetworkSession: NSObject {
        
    static var shared = P2PNetworkSession()

    var delegates = [P2PNetworkSessionDelegate]() // TODO: Weak Ref?

    let myPlayer = Player.myself
    let session: MCSession
    let advertiser: MCNearbyServiceAdvertiser
    let browser: MCNearbyServiceBrowser
    
    private var playersLock = NSLock()
    private var players = [Player]() // protected with playersLock
    private var sessionStates = [MCPeerID: MCSessionState]() // protected with playersLock
    
    private var sessionHost: MCPeerID? // The one who invites the others
    
    // Discovery
    private let startTime = Date().timeIntervalSince1970

    var connectedPeers: [Player] {
        prettyPrint(level: .debug, "\(session.connectedPeers)")
        return players//session.connectedPeers.map{Player($0)}
    }

    /// - Tag: MultipeerSetup
    override init() {
        let myPeerID = myPlayer.peerID
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID,
                                                      discoveryInfo: ["startTime": "\(startTime)"],
                                                      serviceType: P2PConstants.networkChannelName)
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: P2PConstants.networkChannelName)
        super.init()
        
        session.delegate = self
        
        NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in
            self?.stopServices()
            self?.session.disconnect()
            self?.session.delegate = nil
        }
    }
    
    func start() {
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        
        browser.delegate = self
        browser.startBrowsingForPeers()
    }
    
    deinit {
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
        playersLock.lock()
        defer { playersLock.unlock() }
        return sessionStates[peer]
    }
    
    func send(data: Data) {
        if session.connectedPeers.count > 0 {
            do {
                try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            } catch {
                prettyPrint(level: .error, "error sending data to peers: \(error.localizedDescription)")
            }
        }
    }
    
    func addDelegate(_ delegate: P2PNetworkSessionDelegate) {
        delegates.append(delegate)
    }
}

extension P2PNetworkSession: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        prettyPrint("Session state of \(peerID.displayName) changed to \(state)")

        playersLock.lock()
        sessionStates[peerID] = state
        playersLock.unlock()

        let player = Player(peerID)
        switch state {
        case .connected:
            playersLock.lock()
            if !players.contains(player) {
                players.append(player)
            }
            playersLock.unlock()
        case .connecting:
            break
        case .notConnected:
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 3)
        default:
            fatalError(#function + " - Unexpected multipeer connectivity state.")
        }
        
        for delegate in delegates {
            delegate.p2pNetworkSession(self, didUpdate: Player(peerID))
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let json = try? JSONSerialization.jsonObject(with: data) {
            prettyPrint("Received: \(json)")
        }

        for delegate in delegates {
            delegate.p2pNetworkSession(self, didReceive: data, from: Player(peerID))
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
        prettyPrint("Found peer: \(peerID.displayName)")
        
        playersLock.lock()
        let player = Player(peerID)
        if !players.contains(player) {
            players.append(player)
        }
        playersLock.unlock()
        
        if let other = info?["startTime"], let otherStartTime = Double(other), startTime < otherStartTime {
            let connectedPeer = session.connectedPeers.first { $0 == peerID }
            if connectedPeer == nil {
                prettyPrint("Inviting peer: \(peerID.displayName)")
                browser.invitePeer(peerID, to: session, withContext: nil, timeout: 3) // Soen't matter if you were connected
            }
        }
        
        for delegate in delegates {
            delegate.p2pNetworkSession(self, didUpdate: Player(peerID))
        }
    }

    public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        prettyPrint("Lost peer: \(peerID.displayName)")

        playersLock.lock()
        let player = Player(peerID)
        players.removeAll { $0 == player }
        playersLock.unlock()
        
        // TODO: If current devices loose all connection
        //        session.disconnect()
        //        browser.startBrowsingForPeers()
        
        for delegate in delegates {
            delegate.p2pNetworkSession(self, didUpdate: Player(peerID))
        }
    }
}

extension P2PNetworkSession: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        prettyPrint("Accepting Peer invite from \(peerID.displayName)")
        invitationHandler(true, self.session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        prettyPrint(level:.error, "Error: \(error.localizedDescription)")
    }
}
