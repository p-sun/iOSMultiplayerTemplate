//
//  BrowserView.swift
//  P2PKitExample
//
//  Created by Paige Sun on 4/29/24.
//

import SwiftUI
import Foundation
import MultipeerConnectivity
import P2PKit

struct ShowBrowserButton: View {
    @State private var isPresented = false
    @StateObject private var browerViewDelegate = BrowerViewDelegate()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Apple's UIController")
                .p2pTitleStyle()
            Button("Open MCBrowserViewController") {
                isPresented = true
            }.sheet(isPresented: $isPresented) {
                BrowerViewHost(browerViewDelegate)
            }
        }.p2pButtonStyle()
    }
}

struct BrowerViewHost: UIViewControllerRepresentable {
    typealias UIViewControllerType = MCBrowserViewController
    
    weak var delegate: BrowerViewDelegate?
    
    init(_ delegate: BrowerViewDelegate) {
        self.delegate = delegate
    }
    
    func makeUIViewController(context: Context) -> MCBrowserViewController {
        let controller = P2PNetwork.makeBrowserViewController()
        if let delegate = delegate {
            controller.delegate = delegate
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: MCBrowserViewController, context: Context) {
    }
}

class BrowerViewDelegate: NSObject, MCBrowserViewControllerDelegate, ObservableObject {
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true)
    }
}

#Preview {
    ShowBrowserButton()
}
