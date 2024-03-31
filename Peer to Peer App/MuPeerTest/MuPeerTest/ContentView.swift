//  created by musesum on 8/9/23.

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject public var peersVm = PeersVm.shared
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            PeersView(peersVm)
            DraggableCircle()
        }
        .padding()
    }
}

struct DraggableCircle: View {
    @StateObject private var playerNetworking = PlayerNetworking<SendableEntity>(defaultSendable: SendableEntity(sender: "", point: CGPoint(x: 200, y: 200)))

    var body: some View {
        Circle()
            .frame(width: 50, height: 50)
            .foregroundColor(.blue)
            .position(playerNetworking.entity.point)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        playerNetworking.entity = SendableEntity(sender: PeersVm.shared.playerId, point: value.location)
                    }
            )
            .task {
                playerNetworking.listen { entity in
                     print("Received new entity", entity)
                }
            }
    }
}

//#Preview {
//    ContentView()
//}
