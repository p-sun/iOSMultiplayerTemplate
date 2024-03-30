//
//  ImmersiveView.swift
//  CardVision
//
//  Created by John Haney (Lextech) on 3/29/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    @Environment(CardViewModel.self) var model
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @Environment(\.openWindow) var openWindow
    var body: some View {
        RealityView { content in
            content.add(model.setupContentEntity())
        }
        .task {
            do {
                if model.dataProvidersAreSupported && model.isReadyToRun {
                    try await model.runSession()
                } else {
                    await dismissImmersiveSpace()
                }
            } catch {
                logger.error("Failed to start session: \(error)")
                await dismissImmersiveSpace()
                openWindow(id: "error")
            }
        }
        .task {
            await model.processUpdates()
        }
        .task {
            await model.monitorSessionEvents()
        }
        .task(priority: .low) {
            await model.processLowUpdates()
        }
        .onChange(of: model.errorState) {
            openWindow(id: "error")
        }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
}
