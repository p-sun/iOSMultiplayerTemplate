//
//  P2PHostSelector.swift

import Foundation
import MultipeerConnectivity

enum HostAction: Codable {
    case requestHost
    case announceHost(hostStartTime: TimeInterval)
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
    private let _hostEventService = P2PEventService<HostAction>("P2PKit.HostAction")
    
    init() {
        P2PNetwork.addPeerDelegate(self)
        
        _hostEventService.onReceive() {
            [weak self] eventInfo, hostAction, json, sender in
            
            let peers = P2PNetwork.connectedPeers
            guard let self = self else { return }
            switch hostAction {
            case .requestHost:
                if host?.isMe == true {
                    announceHostEvent(to: [sender])
                }
            case .announceHost(let hostStartTime):
                let hostPeer = peers.first(where: { $0.peerID == sender })
                if let hostPeer = hostPeer {
                    _lock.lock()
                    if let host = self._host,
                       let myStartTime = _hostStartTime,
                       host.isMe && myStartTime > hostStartTime {
                        _lock.unlock()
                        announceHostEvent(to: [hostPeer.peerID])
                    } else {
                        _lock.unlock()
                        setHost(hostPeer)
                    }
                } else {
                    prettyPrint(level: .error, "Received host announcement, but I'm not fully connected to host.")
                    Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false) { [weak self] _ in
                        self?._hostEventService.send(payload: .requestHost, to: [sender], reliable: true)
                    }.fire()
                    setHost(nil)
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
        _host = host
        _lock.unlock()
        
        prettyPrint("Setting new Host [\(host?.displayName ?? nil)]")
        didUpdateHost?(host)
        
        if host?.isMe == true {
            announceHostEvent()
        }
    }
    
    private func announceHostEvent(to peers: [MCPeerID] = []) {
        _lock.lock()
        if let hostStartTime = _hostStartTime {
            _lock.unlock()
            _hostEventService.send(payload: .announceHost(hostStartTime: hostStartTime), to: peers, reliable: true)
        } else {
            _lock.unlock()
        }
    }
}

extension P2PHostSelector: P2PNetworkPeerDelegate {
    func p2pNetwork(didUpdate peer: Peer) {
        _lock.lock()
        if let host = _host {
            _lock.unlock()
            let connectedPeers = P2PNetwork.connectedPeers
            if host.isMe {
                if connectedPeers.contains(peer) {
                    // Announce to newly connected Peers that I am host
                    announceHostEvent(to: [peer.peerID])
                }
            } else if !connectedPeers.contains(where: { $0.peerID == host.peerID }) {
                // I've lost connection to existing host
                setHost(nil)
            }
        } else {
            _lock.unlock()
        }
    }
    
    func p2pNetwork(didUpdateHost host: Peer?) {
        // Intentionally empty
    }
}
