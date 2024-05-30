//
//  GameTab.swift
//  P2PKitDemo

import SwiftUI

struct GameTab: View {
    @State private var showGame = false
    @StateObject private var connected = ConnectedPeers()
    
    var body: some View {
        if showGame {
            AirHockeyView()
        } else {
            LobbyView(connected: connected)
                .onChange(of: connected.host) {
                    showGame = connected.host != nil
                }
        }
    }
}
