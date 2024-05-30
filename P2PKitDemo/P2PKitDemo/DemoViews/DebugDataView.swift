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
    
    private let eventHandlers = P2PEventService<Int>("")
    
    init() {
        eventHandlers.onReceiveData { [weak self] data, json, sender in
            guard let self = self, let json = json else { return }
            
            let data = try! JSONSerialization.data(
                withJSONObject: json,
                options: [.prettyPrinted, .sortedKeys]
            )
            let jsonStr = String(data: data, encoding: .utf8)!

            DispatchQueue.main.async {
                self.recentJsons = ["\(jsonStr)"] +  Array(self.recentJsons[0..<self.recentJsons.count - 1])
                self.text = self.recentJsons.joined(separator: "/n")
            }
            return
        }
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
