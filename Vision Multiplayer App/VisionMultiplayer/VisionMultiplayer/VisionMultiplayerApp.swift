//
//  VisionMultiplayerApp.swift
//  VisionMultiplayer
//
//  Created by Paige Sun on 3/30/24.
//

import SwiftUI

@main
struct VisionMultiplayerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }.immersionStyle(selection: .constant(.full), in: .full)
    }
}
