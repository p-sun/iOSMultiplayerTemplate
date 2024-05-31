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
import P2PKit

func setupP2PKit() {
    P2PConstants.networkChannelName = "my-p2p-service"
    P2PConstants.loggerEnabled = true
    P2PNetwork.start()
}

struct ContentView: View {
    var body: some View {
        Group {
            TabView() {
                GameTab()
                    .tag(0)
                    .edgesIgnoringSafeArea(.top)
                    .tabItem {
                        Label("Game", systemImage: "gamecontroller.fill")
                    }
                DebugTab
                    .tag(1)
                    .safeAreaPadding()
                    .tabItem {
                        Label("Debug", systemImage: "newspaper.fill")
                    }
            }
        }
        .tint(.mint)
        .task {
            setupP2PKit()
        }
    }
        
    var DebugTab: some View {
        VStack(alignment: .leading) {
            PeerListView()
            SyncedCounter()
            SyncedCircles()
            DebugDataView()
            Spacer()
        }.frame(maxWidth: 480)
    }
}

#Preview {
    ContentView()
}
