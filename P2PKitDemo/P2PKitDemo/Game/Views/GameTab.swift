//
//  GameTab.swift
//  P2PKitDemo

import SwiftUI
import P2PKit

enum GameTabState {
    case unstarted
    case startedGame
    case pausedGame
}

struct GameTab: View {
    @StateObject private var connected = ConnectedPeers()
    @State private var state: GameTabState = .unstarted
    
    var body: some View {
        ZStack {
            if state == .unstarted {
                LobbyView(connected: connected) {
                    if connected.peers.count > 0 {
                        BigButton("Create Room") {
                            P2PNetwork.makeMeHost()
                        }
                    }
                    BigButton("Play Solo") {
                        P2PNetwork.soloMode = true
                        P2PNetwork.makeMeHost()
                    }
                }
            } else {
                AirHockeyView()
                if state == .pausedGame {
                    LobbyView(connected: connected) {
                        BigButton("Continue Room") {
                            P2PNetwork.makeMeHost()
                        }
                    }.background(.white)
                }
            }
        }.onChange(of: connected.host) {
            state = connected.host == nil ? .pausedGame : .startedGame
        }
    }
    
    private func BigButton(_ text: String, action: @escaping () -> Void) -> some View {
        Button(action: action, label: {
            Text(text).padding(10).font(.title)
        }).p2pButtonStyle()
    }
}
