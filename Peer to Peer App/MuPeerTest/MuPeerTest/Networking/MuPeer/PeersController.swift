// Created by musesum on 12/4/22.

import UIKit
import MultipeerConnectivity

public protocol PeersControllerDelegate: AnyObject {
    func received(data: Data, viaStream: Bool) -> Bool
    func sessionDidUpdate()
}

public typealias PeerName = String

/// advertise and browse for peers via Bonjour
public class PeersController: NSObject {

    public static var shared = PeersController()
    
    private let startTime = Date().timeIntervalSince1970

    public var peerState = [PeerName: MCSessionState]()
    public var peersDelegates = [PeersControllerDelegate]()
    
    public func remove(peersDelegate: PeersControllerDelegate) {
        peersDelegates = peersDelegates.filter { return $0 !== peersDelegate }
    }
        
    lazy var myName: PeerName =  {
        return UIDevice.current.name + " | " + UIDevice.current.identifierForVendor!.uuidString
    }()
    
    lazy var session: MCSession = {
        let myPeerId = MCPeerID(displayName: myName)
        let session = MCSession(peer: myPeerId)
        session.delegate = self
        return session
    }()

    private lazy var advertiser: MCNearbyServiceAdvertiser = {
        return MCNearbyServiceAdvertiser(peer: session.myPeerID, discoveryInfo: nil, serviceType: PSChannelName)
    }()
    
    private lazy var browser: MCNearbyServiceBrowser = {
        return MCNearbyServiceBrowser(peer: session.myPeerID, serviceType: PSChannelName)
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
        browser.delegate = self
        browser.startBrowsingForPeers()
    }

    func startAdvertising() {
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
    }

    private func stopServices() {
        advertiser.stopAdvertisingPeer()
        advertiser.delegate = nil

        browser.stopBrowsingForPeers()
        browser.delegate = nil
    }
    
    private func elapsedTime() -> TimeInterval {
        Date().timeIntervalSince1970 - startTime
    }

    func logPeer(_ body: PeerName) {
        #if true
        let logTime = String(format: "%.2f", elapsedTime())
        print("⚡️ \(logTime): \(body)")
        #endif
    }
}

extension PeersController {

    /// send message to peers
    public func sendMessage(_ message: Encodable,
                            viaStream: Bool) {
        if session.connectedPeers.isEmpty {
            //print("⁉️", terminator: "")
            return
        }
        do {
            let data = try JSONEncoder().encode(message)
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
                try session.send(data, toPeers: session.connectedPeers, with: .unreliable)
                logPeer("⚡️send toPeers")
            }
        } catch {
            logPeer("\(#function) error: \(error.localizedDescription)")
        }
    }
}

extension Hashable {
    func combineHash(with hashableOther: any Hashable) -> Int {
        let ownHash = self.hashValue
        let otherHash = hashableOther.hashValue
        return (ownHash << 5) &+ ownHash &+ otherHash
    }
}
