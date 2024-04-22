//  created by musesum on 8/9/23.

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject public var peersVm = PeersVm.shared
    @StateObject var blueCircle = PSNetworkingObservable(name: "blue", initial: SendableCircle(point: CGPoint(x: 100, y: 100)))
    @StateObject var greenCircle = PSNetworkingObservable(name: "green", initial: SendableCircle(point: CGPoint(x: 240, y: 240)))

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            PeersView(peersVm)
            ZStack {
                DraggableCircle(color: .blue, networking: blueCircle)
                DraggableCircle(color: .green, networking: greenCircle)
            }
        }
        .padding()
    }
}

struct DraggableCircle: View {
    let color: Color
    @ObservedObject var networking: PSNetworkingObservable<SendableCircle>
    
    var body: some View {
        VStack {
            Circle()
                .frame(width: 80, height: 80)
                .foregroundColor(color)
                .position(networking.value.point)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            networking.send(SendableCircle(point: value.location))
                        }
                )
        }
    }
}

#Preview {
    ContentView()
}
