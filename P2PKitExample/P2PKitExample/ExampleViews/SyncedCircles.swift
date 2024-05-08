//
//  SyncedCircles.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/3/24.
//

import SwiftUI

struct ShowSyncedCirclesButton: View {
    @State private var isPresented = false
    @StateObject private var browerViewDelegate = BrowerViewDelegate()
    
    var body: some View {
        VStack(alignment: .leading) {
            Button("Show Synced Circles") {
                isPresented = true
            }.sheet(isPresented: $isPresented) {
                SyncedCircles()
            }
        }.p2pButtonStyle()
    }
}

struct SendableCircle: Codable {
    var point: CGPoint
}

struct SyncedCircles: View {
    @StateObject var blueCircle = P2PNetworkedEntity(name: "blue", initial: SendableCircle(point: CGPoint(x: 100, y: 100)))
    @StateObject var greenCircle = P2PNetworkedEntity(name: "green", initial: SendableCircle(point: CGPoint(x: 240, y: 240)))
    
    var body: some View {
        ZStack {
            DraggableCircle(color: .blue, networking: blueCircle)
            DraggableCircle(color: .green, networking: greenCircle)
        }
        .frame(height: 200)
        .background(Color.indigo.opacity(0.3))
    }
}

struct DraggableCircle: View {
    let color: Color
    @ObservedObject var networking: P2PNetworkedEntity<SendableCircle>

    var body: some View {
        VStack {
            Circle()
                .frame(width: 80, height: 80)
                .foregroundColor(color)
                .position(networking.value.point)
                .highPriorityGesture(
                    DragGesture()
                        .onChanged { value in
                            print("on changed", value.location.x)
                            networking.value = SendableCircle(point: value.location)
                        }
                )
        }
    }
}

#Preview {
    ContentView()
}
