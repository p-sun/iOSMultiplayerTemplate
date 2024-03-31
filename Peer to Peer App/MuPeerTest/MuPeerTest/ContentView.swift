//  created by musesum on 8/9/23.

import SwiftUI

struct ContentView: View {
    @StateObject public var peersVm = PeersVm.shared
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            PeersView(peersVm)
            DraggableCircle(circle: $peersVm.circle)
        }
        .padding()
    }
}

struct DraggableCircle: View {
    @Binding var circle: SendableEntity
    
    
    var body: some View {
        Circle()
            .frame(width: 50, height: 50)
            .foregroundColor(.blue)
            .position(circle.point)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        self.circle = SendableEntity(owner: PeersVm.shared.playerId, point: value.location)
                    }
            )
    }
}


//#Preview {
//    ContentView()
//}
