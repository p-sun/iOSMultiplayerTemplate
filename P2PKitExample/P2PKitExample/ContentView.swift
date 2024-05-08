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
    var body: some View {
        Group {
            TabView(selection: .constant(0)) {
                DebugTab
                    .tag(0)
                    .safeAreaPadding()
                    .tabItem {
                        Label("Debug", systemImage: "newspaper.fill")
                    }
                GameTab
                    .tag(1)
                    .safeAreaPadding()
                    .tabItem {
                        Label("Game", systemImage: "gamecontroller.fill")
                    }
            }
        }.tint(.mint)
    }
    
    var GameTab: some View {
        VStack(alignment: .leading) {
            Image(systemName: "gamecontroller.fill")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Spacer()
        }
    }
    
    var DebugTab: some View {
        VStack(alignment: .leading) {
            PeerListView()
            CounterView()
            SyncedCircles()
            DebugDataView()
        }
    }
}

#Preview {
    ContentView()
}
