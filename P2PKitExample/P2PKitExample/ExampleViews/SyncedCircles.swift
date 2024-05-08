//
//  SyncedCircles.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/3/24.
//

import SwiftUI

struct SendableCircle: Codable {
    var point: CGPoint
}

struct SyncedCircles: View {
    @StateObject var blueCircle = P2PNetworkedEntity(name: "blue", initial: SendableCircle(point: CGPoint(x: 300, y: -58)))
    @StateObject var greenCircle = P2PNetworkedEntity(name: "green", initial: SendableCircle(point: CGPoint(x: 300, y: 30)))
    
    var body: some View {
        VStack {
            Text("Sync Data")
                .p2pTitleStyle()
            ShowSyncedCirclesButton()
            ZStack {
                DraggableCircle(color: .blue, networking: blueCircle)
                DraggableCircle(color: .green, networking: greenCircle)
            }
        }
        .frame(height: 180)
        .background(Color.indigo.opacity(0.3))
    }
}

struct ShowSyncedCirclesButton: View {
    @State private var isPresented = false
    
    var body: some View {
        HStack {
            Button("Present in New Sheet") {
                isPresented = true
            }.sheet(isPresented: $isPresented) {
                SyncedCircles()
            }.p2pButtonStyle()
            Spacer()
        }
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
                            networking.value = SendableCircle(point: value.location)
                        }
                )
        }
    }
}

#Preview {
    ContentView()
}
