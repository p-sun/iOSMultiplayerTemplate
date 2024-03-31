
import SwiftUI

import MultipeerConnectivity

/// This is the View Model for PeersView
public class PeersVm: ObservableObject {

    public static let shared = PeersVm()

    /// myName and one second counter
    @Published var peersTitle = "Bonjour"

    /// list of connected peers and their counter
    @Published var peersList = ""
    
    @Published var circleLocation = CGPoint(x: 200, y: 200) {
        didSet {
            if circleLocation != oldValue {
                let sendable = SendableEntity(peerName: peersController.myName, point: circleLocation)
                peersController.sendMessage(sendable, viaStream: false)
            }
        }
    }

    private var peersController: PeersController
    private var peerCounter = [String: Int]()
    private var peerStreamed = [String: Bool]()

    public init() {
        peersController = PeersController.shared
        peersController.peersDelegates.append(self)
        oneSecondCounter()
    }
    deinit {
        peersController.remove(peersDelegate: self)
    }

    /// create a 1 second counter and send my count to all of my peers
    private func oneSecondCounter() {
        var count = Int(0)
        let myName = peersController.myName
        func loopNext() {
            count += 1

            // viaStream: false will use MCSessionDelegate
            // viaStream: true  will use StreamDelegate
            let sendable = SendablePeer(peerName: myName, count: count)
            // ["peerName": myName, "count": count, "position": DotPoint(circleLocation)]
            peersController.sendMessage(sendable,
                                        viaStream: false)
            peersTitle = "\(myName): \(count)"
        }
        _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: true)  {_ in
            loopNext()
        }
    }
}
extension PeersVm: PeersControllerDelegate {

    public func didChange() {

        var peerList = ""

        for (name,state) in peersController.peerState {

            peerList += "\n \(state.icon()) \(name)"

            if let count = peerCounter[name]  {
                peerList += ": \(count)"
            }
            if let streamed = peerStreamed[name] {
                peerList += streamed ? "💧" : "⚡️"
            }
        }
        self.peersList = peerList
    }

    public func received(data: Data, viaStream: Bool) -> Bool {
//        do {
            if let sendable = try? JSONDecoder().decode(SendablePeer.self, from: data) {
                peersController.fixConnectedState(for: sendable.peerName)
                peerCounter[sendable.peerName] = sendable.count
                peerStreamed[sendable.peerName] = viaStream
                didChange()
                return true
            } else if let sendableEntity = try? JSONDecoder().decode(SendableEntity.self, from: data) {
                if sendableEntity.peerName != peersController.myName {
                    circleLocation = sendableEntity.point
                }
                return true
            }
//        } catch {
//            print("Received error. Can't decode. ", error)
//        }
        return false
    }

}
