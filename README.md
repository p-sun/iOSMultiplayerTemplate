# VisionProMultiplayer
Bluetooth or WiFi Networking with Apple's Multipeer Connectivity framework for hackathons. 
Builds for all iOS, including Vision Pro, iPhone, and iPad. For best performance across real devices, disable WiFi to use bluetooth connection.

### Game Demo
You're the mallet with the star. When the white puck enters a hole, the last person to touch the white puck with their mallet scores a point!

https://github.com/p-sun/iOSMultiplayerTemplate/assets/9044578/53169d75-bbda-4401-a376-e77a6dae1371

# APIs

https://github.com/p-sun/iOSMultiplayerTemplate/assets/9044578/5610f760-0c3c-4100-b1ca-cbcb417c72b0

## Use P2PSynced to sync Codable data
P2PSynced is the easiest way to sync data across devices.
```swift
let syncedRoom = P2PSynced<GameRoom>(
        name: "GameRoom",
        initial: GameRoom(),
        writeAccess: .hostOnly, // Optional param. Defaults to .everyone has write access. If using .hostOnly, set host with `P2PNetwork.makeMeHost()`.
        reliable: true) // Optional param. Defaults to false. Reliable sending is slower but preserves order and doesn't drop messages.

// GET data
syncedRoom.onReceiveSync = { gameRoom in }

// SEND DATA
syncedRoom.value = GameRoom(...) 
```

## Use P2PSyncedObservable with Swift UI
Use P2PSyncedObservable, a light wrapper around P2PSynced, with SwiftUI.

In this example, an Int value is sent between devices to sync a counter.
```swift
struct SyncedCounter: View {
    @StateObject private var counter = P2PSyncedObservable(name: "SyncedCounter", initial: 1)
    
    var body: some View {
        Button("+ 1") {
            counter.value = counter.value + 1 // SET VALUE
        }
        Text("Counter: \(counter.value)") // RECEIVE VALUE
    }
}
```

Similarily, in the [SyncedCircles example](https://github.com/p-sun/iOSMultiplayerTemplate/blob/main/P2PKitDemo/P2PKitDemo/DemoViews/SyncedCircles.swift), the Codable object `SendableCircle`, is synced across all devices.

```swift
@StateObject var blueCircle = P2PSyncedObservable(name: "blue", initial: SendableCircle(point: CGPoint(x: 300, y: -26)))
@StateObject var greenCircle = P2PSyncedObservable(name: "green", initial: SendableCircle(point: CGPoint(x: 260, y: -10)))

// RECEIVE
let sendableCircle = blueCircle.value

// SEND
blueCircle.value = SendableCircle(point: newPoint)
```

## Use P2PEventService to send/receive Codable events

```swift
let malletDraggedEvents = P2PEventService<MalletDragEvent>("MalletDrag")

// RECEIVE
malletDraggedEvents.onReceive { eventInfo, malletDragEvent, json, sender in
  // Handle malletDragEvent
}

// SEND
malletDraggedEvents.send(payload: MalletDragEvent(...), reliable: false)
```

## P2PNetworkDelegate
Get myself and connected peers.
```swift
let myPeer: Peer = P2PNework.myPeer
```
```swift
let connectedPeers: [Peer] = P2PNework.connectedPeers
```

Observe peer updates with `P2PNetworkPeerDelegate`. When connectedPeers update, the `p2pNetwork(didUpdate peer: Peer)` handler will be called.
```swift
protocol P2PNetworkPeerDelegate: AnyObject {
    func p2pNetwork(didUpdate peer: Peer)
    func p2pNetwork(didUpdateHost host: Peer?)
}
```
```swift
P2PNework.addPeerDelegate(self)
P2PNework.removePeerDelegate(self)

```

(Optional) Reset the session.
```swift
P2PNework.resetSession("New Display Name") // Change display name.
P2PNework.resetSession(nil) // Keep current display name.
```

(Optional) Get and set the host for all connected devices. Not all games need a host.
```swift
let currentHost: Peer? = P2PNework.host
```

```swift
P2PNework.makeMeHost()
```

# Bonus: Host Features
### Host Selection
* Whoever taps "Create Room" acts as the host server with the game's source of truth, streaming game physics to everyone.
* Non-hosts disconnect and reconnects automatically, and their score will resume.
* When a host disconnects, other players get the "Continue Room" button, and the first player to tap that button becomes the host.
* Any previous host will accept the new host.
  
https://github.com/p-sun/iOSMultiplayerTemplate/assets/9044578/469ae3dc-5c19-4a4f-a74d-32ffdeb422a4

### Host resumes data

When the current device connects to a host, `P2PSynced` and `P2PSyncedObservable` will sync the latest data from the host.

https://github.com/p-sun/iOSMultiplayerTemplate/assets/9044578/9755a6d7-e04b-4dc9-b900-38b60b50c24e
