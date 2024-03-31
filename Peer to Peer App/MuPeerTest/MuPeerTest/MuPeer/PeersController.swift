// Created by musesum on 12/4/22.

import UIKit
import MultipeerConnectivity

public protocol PeersControllerDelegate: AnyObject {
    func didChange()
    func received(data: Data, viaStream: Bool) -> Bool
}

public typealias PeerName = String

/// advertise and browse for peers via Bonjour
public class PeersController: NSObject {

    public static var shared = PeersController()

    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    private let startTime = Date().timeIntervalSince1970

    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    public var peerState = [PeerName: MCSessionState]()
    public var hasPeers = false
    public var peersDelegates = [any PeersControllerDelegate]()
    public func remove(peersDelegate: any PeersControllerDelegate) {
        peersDelegates = peersDelegates.filter { return $0 !== peersDelegate }
    }
    public lazy var session: MCSession = {
        let session = MCSession(peer: self.myPeerID)
        session.delegate = self
        return session
    }()
    public lazy var myName: PeerName = {
        return session.myPeerID.displayName
    }()
    public lazy var mySessionId: Int = {
        return myName.hash + Int(Date().timeIntervalSince1970)
    }()
    
    override init() {
        super.init()
        startAdvertising()
        startBrowsing()
    }
    deinit {
        stopServices()
        session.disconnect()
        session.delegate = nil
    }

    func startBrowsing() {
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: PeerServiceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
    }

    func startAdvertising() {
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: PeerServiceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }

    private func stopServices() {
        advertiser?.stopAdvertisingPeer()
        advertiser?.delegate = nil

        browser?.stopBrowsingForPeers()
        browser?.delegate = nil
    }
    private func elapsedTime() -> TimeInterval {
        Date().timeIntervalSince1970 - startTime
    }

    func logPeer(_ body: PeerName) {
        #if false
        let logTime = String(format: "%.2f", timeElapsed())
        print("⚡️ \(logTime) \(myName): \(body)")
        #endif
    }
}

extension PeersController {

    /// send message to peers
    public func sendMessage(_ message: [String : Any],
                            viaStream: Bool) {
        if session.connectedPeers.isEmpty {
            //print("⁉️", terminator: "")
            return
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: message, options: .prettyPrinted)
            sendMessage(data, viaStream: viaStream)
        } catch {
            logPeer("\(#function) error: \(error.localizedDescription)")
            return
        }
    }
    /// send message to peers
    public func sendMessage(_ data: Data,
                            viaStream: Bool) {
        do {
            if viaStream {
                for peerID in session.connectedPeers {
                    let peerName = peerID.displayName
                    let streamName = "\(elapsedTime()): \"\(peerName)\""

                    if let outputStream = try? session.startStream(withName: streamName, toPeer: peerID) {
                        outputStream.delegate = self
                        outputStream.schedule(in: .main,  forMode: .common)
                        outputStream.open()
                        let count = outputStream.write(data.bytes, maxLength: data.bytes.count)
                        outputStream.close()
                        logPeer("💧send: toPeer: \"\(peerName)\" bytes: \(count)")
                    }
                }
            } else {
                // via session
                try session.send(data, toPeers: session.connectedPeers, with: .reliable)
                logPeer("⚡️send toPeers")
            }
        } catch {
            logPeer("\(#function) error: \(error.localizedDescription)")
        }
    }

    /// Sometimes a .notConnect state is sent from peer and yet still receiving messaages.
    ///
    /// There is a long standing GCKSession issue that throws up a NSLog:
    ///
    ///     [GCKSession] Not in connected state, so giving up for participant ...
    ///     // not sure if this is related to false .nonConnected

    func fixConnectedState(for peerName: String) {
        peerState[peerName] = .connected
    }

}
