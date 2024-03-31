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
            DraggableCircle(circlePosition: $peersVm.circleLocation)
        }
        .padding()
    }
}

struct DraggableCircle: View {
    @Binding var circlePosition: CGPoint
    
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
