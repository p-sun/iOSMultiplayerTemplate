//
//  ContentView.swift
//  P2PKitExample
//
//  Created by Paige Sun on 4/22/24.

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
                .padding()
            ScrollView {
                PeerListView()
                CounterView()
            }
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
