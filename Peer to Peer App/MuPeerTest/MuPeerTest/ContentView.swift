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
            DraggableCircle(name: "blue", color: .blue)
            DraggableCircle(name: "green", color: .green)
        }
        .padding()
    }
}

struct DraggableCircle: View {
    let color: Color
    let networking: PSNetworking<SendableCircle>
    @State var position: CGPoint = CGPoint(x: 200, y: 200)
    
    init(name: String, color: Color) {
        self.networking = PSNetworking(name: name)
        self.color = color
    }
    
    var body: some View {
        VStack {
            Circle()
                .frame(width: 50, height: 50)
                .foregroundColor(color)
                .position(position)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            position = value.location
                            networking.send(SendableCircle(point: value.location))
                        }
                ).task {
                    networking.listen { entity in
                        position = entity.point
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
