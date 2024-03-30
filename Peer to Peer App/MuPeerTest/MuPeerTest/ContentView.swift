//  created by musesum on 8/9/23.

import SwiftUI
import MuPeer

struct ContentView: View {
    public var peersVm = PeersVm.shared
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
    @State private var circlePosition = CGPoint(x: 200, y: 200)
    
    var body: some View {
        Circle()
            .frame(width: 50, height: 50)
            .foregroundColor(.blue)
            .position(circlePosition)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        self.circlePosition = value.location
                    }
            )
    }
}

//#Preview {
//    ContentView()
//}
