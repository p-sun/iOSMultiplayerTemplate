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
            ScrollView {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                    .tint(.mint)
                VStack(alignment: .leading) {
                    PeerListView()
    //                Button("Send Test Event") {
    //                    let data = try! JSONEncoder().encode(["testEvent": "Time: \(Date().formatted())"])
    //                    P2PNetwork.send(data: data)
    //                }.p2pButtonStyle()
                    CounterView()
                    VStack(alignment: .leading) {
                        Text("Sync Data")
                            .p2pTitleStyle()
                        SyncedCircles()
                        ShowSyncedCirclesButton()
                    }
                    DebugDataView()
                }
            }
        }.padding()
    }
}

#Preview {
    ContentView()
}
