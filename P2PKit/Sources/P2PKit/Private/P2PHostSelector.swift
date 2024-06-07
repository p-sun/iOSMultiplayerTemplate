//
//  P2PHostSelector.swift

import Foundation
import MultipeerConnectivity

enum HostEvent: Codable {
    case announceHost(hostStartTime: TimeInterval) // "I am host"
    case announceHostCandidate(hostUpdateTime: TimeInterval) // "May I become host?"
    case respondYesToHostCandidacy // "Yes, you may become host"
}

// Decides whether current user should become the next host
private class HostCandidate {
    var timeoutTimer: Timer
    var receivedYesFrom = Set<MCPeerID>()
    
    init(timeoutTimer: Timer) {
        self.timeoutTimer = timeoutTimer
    }
}

// Decide which connected peer is the leader/host.
class P2PHostSelector {
    var didUpdateHost: ((_ host: Peer?) -> Void)? = nil
    
    var host: Peer? {
        _lock.lock(); defer { _lock.unlock() }
        return _host
    }
    
    private var _lock = NSLock()
    private var _host: Peer? = nil
    // If the current player is the host, the time that player became host.
    private var _hostStartTime: TimeInterval?
    // If there had been a host in the past, the time the last host was lost
    private var _hostUpdateTime: TimeInterval = 0
    private var _hostCandidate: HostCandidate? = nil
    
    private let _hostEventService = P2PEventService<HostEvent>("P2PKit.P2PHostSelector")
    
    init() {
        P2PNetwork.addPeerDelegate(self)
        
        _hostEventService.onReceive() {
            [weak self] eventInfo, senderHostEvent, json, sender in
            
            let peers = P2PNetwork.connectedPeers
            guard let self = self else { return }
            switch senderHostEvent {
            case .announceHost(let hostStartTime):
                let senderHost = peers.first(where: { $0.peerID == sender })
                if let senderHost = senderHost {
                    _lock.lock()
                    if let host = self._host,
                       let myStartTime = _hostStartTime,
                       host.isMe && myStartTime > hostStartTime {
                        _lock.unlock()
                        prettyPrint("Received host announcement from [\(senderHost.displayName)], but I'm a newer host. Sending host announcement to everyone.")
                        announceHostEvent(to: [])
                    } else {
                        _lock.unlock()
                        prettyPrint("Received host announcement from [\(senderHost.displayName)]. Accepting as new host.")
                        setHost(senderHost)
                    }
                } else {
                    prettyPrint(level: .error, "Received host announcement from [\(sender.displayName)], but I'm not connected to host.")
                }
            case .announceHostCandidate(let hostUpdateTime):
                let senderHost = peers.first(where: { $0.peerID == sender })
                if let senderHost = senderHost {
                    _lock.lock()
                    if let host = self._host, host.isMe { // I am host
                       _lock.unlock()
                       prettyPrint("Received host candidate from [\(senderHost.displayName)], but I'm a better host. Sending host announcement to sender.")
                       announceHostEvent(to: [sender])
                    } else if let hostCandidate = self._hostCandidate { // I am also a host candidate
                        if self._hostUpdateTime > hostUpdateTime
                            || self._hostUpdateTime == hostUpdateTime && P2PNetwork.myPeer.id < senderHost.id {
                            _lock.unlock()
                            prettyPrint("Received host candidate from [\(senderHost.displayName)], but I'm a better candidate. Responding with my host candidacy.")
                            announceHostCandidacyEvent(to: [sender])
                        } else {
                            _lock.unlock()
                            prettyPrint("Received better host candidate from [\(senderHost.displayName)]. Removing my host candidacy and responding with yes.")
                            _hostEventService.send(payload: .respondYesToHostCandidacy, reliable: true)
                            hostCandidate.timeoutTimer.invalidate()
                            _hostCandidate = nil
                        }
                    } else {
                        _lock.unlock()
                        prettyPrint("Received host candidate from [\(senderHost.displayName)]. Responding with yes.")
                        _hostEventService.send(payload: .respondYesToHostCandidacy, reliable: true)
                    }
                } else {
                    prettyPrint(level: .error, "Received host announcement from [\(sender.displayName)], but I'm not fully connected to host.")
                }
            case .respondYesToHostCandidacy:
                if let hostCandidate = _hostCandidate {
                    hostCandidate.receivedYesFrom.insert(sender)
                    if hasAllConnectedPeersResponded(to: hostCandidate) {
                        prettyPrint("All peers responded yes to my host candidacy. Making myself host.")
                        hostCandidate.timeoutTimer.invalidate()
                        _hostCandidate = nil
                        makeMeHost()
                    }
                }
            }
        }
    }
    
    deinit {
        P2PNetwork.removePeerDelegate(self)
    }
    
    func makeMeHost() {
        _lock.lock()
        _hostStartTime = Date().timeIntervalSince1970
        _lock.unlock()
        setHost(P2PNetwork.myPeer)
    }
    
    private func setHost(_ host: Peer?) {
        _lock.lock()
        if _host != nil && host == nil {
            _hostUpdateTime = Date().timeIntervalSince1970
        }
        _host = host
        _lock.unlock()
        
        prettyPrint("Setting new Host [\(host?.displayName ?? nil)]")
        didUpdateHost?(host)
        
        if host?.isMe == true {
            announceHostEvent()
        }
    }

    private func announceHostEvent(to peers: [MCPeerID] = []) {
        prettyPrint("Announcing that I am host to \(peers.isEmpty ? "everyone" : "\(peers)") ")
        _lock.lock()
        if let hostStartTime = _hostStartTime {
            _lock.unlock()
            _hostEventService.send(payload: .announceHost(hostStartTime: hostStartTime), to: peers, reliable: true)
        } else {
            _lock.unlock()
        }
    }
    
    // Start host election
    private func announceHostCandidacyEvent(to peers: [MCPeerID]) {
        func createTimeoutTimer() -> Timer {
            return Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { [weak self] timer in
                guard let self = self else { return }
                prettyPrint("Timed out after host candidacy annoucement without receiving responses from all connected peers.")
                self._hostCandidate = nil
                
                // Retry if user is still connected to devices
                if !P2PNetwork.connectedPeers.isEmpty && self._host == nil {
                    self.announceHostEvent()
                }
            }
        }
        
        if let hostCandidate = _hostCandidate {
            hostCandidate.timeoutTimer.invalidate()
            prettyPrint("Announcing my host candidacy to peers \(peers.map { $0.displayName })")
            _hostEventService.send(payload: .announceHostCandidate(hostUpdateTime: _hostUpdateTime), to: peers, reliable: true)
            hostCandidate.timeoutTimer = createTimeoutTimer()
        } else {
            _hostCandidate = HostCandidate(timeoutTimer: createTimeoutTimer())
            prettyPrint("Announcing my host candidacy to everyone.")
            _hostEventService.send(payload: .announceHostCandidate(hostUpdateTime: _hostUpdateTime), to: [], reliable: true)
        }
    }
    
    private func hasAllConnectedPeersResponded(to hostCandidate: HostCandidate) -> Bool {
        let connectedPeers = P2PNetwork.connectedPeers
        for peer in connectedPeers {
            if !hostCandidate.receivedYesFrom.contains(peer.peerID) {
                return false
            }
        }
        return true
    }
}

extension P2PHostSelector: P2PNetworkPeerDelegate {
    func p2pNetwork(didUpdate peer: Peer) {
        guard !peer.isMe else { return }
        let connectedPeers = P2PNetwork.connectedPeers
        
        _lock.lock()
        if let host = _host {
            _lock.unlock()
            if !host.isMe && !connectedPeers.contains(host) {
                prettyPrint("Lost connection to host [\(host.displayName)].")
                setHost(nil)
                if !connectedPeers.isEmpty {
                    // "I lost my host. Is anyone the host?"
                    announceHostCandidacyEvent(to: [])
                }
            } else if host.isMe && connectedPeers.isEmpty {
                prettyPrint("Lost connection to all peers. Removing myself as host.")
                setHost(nil)
            } else if host.isMe && connectedPeers.contains(peer) {
                announceHostEvent(to: [peer.peerID])
            }
        } else {
            _lock.unlock()
            // "I have no host, are you the host?"
            if connectedPeers.contains(peer) {
                announceHostCandidacyEvent(to: [peer.peerID])
            }
        }
    }
    
    func p2pNetwork(didUpdateHost host: Peer?) {
        // Intentionally empty
    }
}
