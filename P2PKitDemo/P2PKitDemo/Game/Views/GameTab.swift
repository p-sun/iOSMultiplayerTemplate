//
//  GameTab.swift
//  P2PKitDemo

import SwiftUI
import P2PKit

struct GameTab: View {
    @State private var showGame = false
    @StateObject private var connected = ConnectedPeers()
    @State private var showContinue = false
    
    var body: some View {
        Group {
            if showGame {
                ZStack {
                    AirHockeyView()
                        .onChange(of: connected.host) {
                            showContinue = connected.host == nil
                        }
                        .blur(radius: showContinue ? 10 : 0)
                    if showContinue {
                        ContinueButton {
                            P2PNetwork.makeMeHost()
                        }
                    }
                }
            } else {
                LobbyView(connected: connected)
                    .onChange(of: connected.host) {
                        showGame = connected.host != nil
                    }
            }
        }
    }
    
    private func ContinueButton(action: @escaping () -> Void) -> some View {
        Button(action: action, label: {
            Text("Continue").padding(10).font(.title)
        }).p2pButtonStyle()
    }
}
