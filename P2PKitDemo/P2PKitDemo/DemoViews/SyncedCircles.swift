//
//  SyncedCircles.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/3/24.
//

import SwiftUI
import P2PKit

struct SendableCircle: Codable {
    var point: CGPoint
}

struct SyncedCircles: View {
    @StateObject var blueCircle = P2PSyncedObservable(name: "blue", initial: SendableCircle(point: CGPoint(x: 300, y: -58)))
    @StateObject var greenCircle = P2PSyncedObservable(name: "green", initial: SendableCircle(point: CGPoint(x: 260, y: -30)))
    
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
        .frame(height: 120)
        .background(Color.indigo.opacity(0.3))
    }
}

struct DraggableCircle: View {
    let color: Color
    @ObservedObject var networking: P2PSyncedObservable<SendableCircle>
    
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

#Preview {
    ContentView()
}
