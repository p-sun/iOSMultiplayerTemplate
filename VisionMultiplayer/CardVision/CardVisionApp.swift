//
//  CardVisionApp.swift
//  CardVision
//
//  Created by John Haney (Lextech) on 3/29/24.
//

import SwiftUI
import OSLog

let logger = Logger(subsystem: "com.lextech.CardVisionApp", category: "general")

@main
struct CardVisionApp: App {
    @State private var cardModel: CardViewModel
    
    init() {
        cardModel = CardViewModel()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(cardModel)
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
                .environment(cardModel)
        }
    }
}
