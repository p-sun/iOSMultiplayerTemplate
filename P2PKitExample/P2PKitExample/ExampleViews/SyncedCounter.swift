//
//  SyncedCounter.swift
//  P2PKitExample
//
//  Created by Paige Sun on 4/28/24.
//

import Foundation
import SwiftUI

struct SyncedCounter: View {
    @StateObject private var networking = P2PSyncedObject<Int>(name: "SyncedCounter", initial: 1)
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Sync Value")
                .p2pTitleStyle()
            HStack {
                Button("+ 1") {
                    networking.value = networking.value + 1
                }.p2pButtonStyle()
                Text("Counter: \(networking.value)")
                Spacer()
            }
        }.background(Color.yellow.opacity(0.3))
    }
}

#Preview {
    SyncedCounter()
}
