//  created by musesum on 8/9/23.

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject public var peersVm = PeersVm.shared
    @StateObject private var playerNetworking = PlayerNetworking<SendableEntity>(defaultSendable: SendableEntity(sender: "", point: CGPoint(x: 200, y: 200)))

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            PeersView(peersVm)
            DraggableCircle(entity: $playerNetworking.entity)
        }
        .padding()
        .task {
            // Get new entity
            playerNetworking.listen { entity in
                //  print("Received new entity", entity)
            }
        }
    }
}

struct DraggableCircle: View {
    @Binding var entity: SendableEntity
    
    var body: some View {
        Circle()
            .frame(width: 50, height: 50)
            .foregroundColor(.blue)
            .position(entity.point)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        entity = SendableEntity(sender: PeersVm.shared.playerId, point: value.location)
                    }
            )
            
    }
}

//#Preview {
//    ContentView()
//}
