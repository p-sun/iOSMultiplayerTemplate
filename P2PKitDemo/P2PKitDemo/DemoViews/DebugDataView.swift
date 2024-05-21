//
//  DebugDataView.swift
//  P2PKitExample
//
//  Created by Paige Sun on 4/29/24.
//

import SwiftUI
import P2PKit
import MultipeerConnectivity

struct DebugDataView: View {
    @StateObject var model = DebugDataViewModel()
    
    var body: some View {
        VStack {
            Text("Receive Data").p2pTitleStyle()
            TextView(text: $model.text)
        }
    }
}

#Preview {
    DebugDataView()
}

class DebugDataViewModel: ObservableObject {
    @Published var text = ""
    
    private var recentJsons = Array(repeating: "", count: 10)
    
    init() {
        P2PNetwork.addDataDelegate(self)
    }
    
    deinit {
        P2PNetwork.removeDataDelegate(self)
    }
}

extension DebugDataViewModel: P2PNetworkDataDelegate {
    func p2pNetwork(didReceive data: Data, dataAsJson json: [String : Any]?, from peer: MCPeerID) -> Bool {
        
        guard let json = json else { return false }
        
        let data = try! JSONSerialization.data(
            withJSONObject: json,
            options: [.prettyPrinted, .sortedKeys]
        )
        let jsonStr = String(data: data, encoding: .utf8)!

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            recentJsons = ["\(jsonStr)"] +  Array(recentJsons[0..<recentJsons.count - 1])
            text = recentJsons.joined(separator: "/n")
        }
        return false
    }
}

private struct TextView: UIViewRepresentable {
    @Binding var text: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> UITextView {
        context.coordinator.textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }
    
    class Coordinator: NSObject {
        lazy var textView: UITextView = {
            let textView = UITextView()
            textView.isEditable = false
            textView.font = UIFont.preferredFont(forTextStyle: .subheadline)
            textView.backgroundColor = .clear
            return textView
        }()
    }
}
