//
//  ContentView.swift
//  P2PKitExample
//
//  Created by Paige Sun on 4/22/24.

/*
 Make sure to add in Info.list:
 NSBonjourServices
 item 0: _my-p2p-service._tcp
 item 1: _my-p2p-service._udp
 
 NSLocalNetworkUsageDescription
 This application will use local networking to discover nearby devices. (Or your own custom message)
 
 Every device in the same room should be able to see each other, whether they're on bluetooth or wifi.
 **/

import SwiftUI

struct ContentView: View {
    @State var isPresented = false
    var body: some View {
        Group {
            TabView(selection: .constant(1)) {
                DebugTab
                    .tag(0)
                    .safeAreaPadding()
                    .tabItem {
                        Label("Debug", systemImage: "newspaper.fill")
                    }
                AirHockeyView()
                    .tag(1)
                    .tabItem {
                        Label("Game", systemImage: "gamecontroller.fill")
                    }
                
                Button("Open Air Hockey In new Window") {
                    isPresented = true
                }.sheet(isPresented: $isPresented) {
                    AirHockeyView()
                }
            }
        }.tint(.mint)
    }
        
    var DebugTab: some View {
        VStack(alignment: .leading) {
            PeerListView()
            SyncedCounter()
            SyncedCircles()
            DebugDataView()
        }
    }
}

#Preview {
    ContentView()
}
