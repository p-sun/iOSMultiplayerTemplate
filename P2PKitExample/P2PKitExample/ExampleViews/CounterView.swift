//
//  CounterView.swift
//  P2PKitExample
//
//  Created by Paige Sun on 4/28/24.
//

import Foundation
import SwiftUI

class CounterModel: ObservableObject {
    @Published var count = 0
    
    init() {
        P2PNetwork.addDelegate(self)
    }
    
    func increment() {
        count += 1
        
        let data = try! JSONEncoder().encode(["count": count])
        P2PNetwork.send(data: data)
    }
}

extension CounterModel: P2PNetworkSessionDelegate {
    func p2pNetworkSession(_ session: P2PNetworkSession, didReceive data: Data, dataAsJson json: [String : Any]?, from player: Player) -> Bool {
        if let newCount = json?["count"] as? Int {
            DispatchQueue.main.async { [weak self] in
                self?.count = newCount
            }
        }
        return false
    }
    
    func p2pNetworkSession(_ session: P2PNetworkSession, didUpdate player: Player) { }
}

struct CounterView: View {
    @StateObject var counter = CounterModel()
    
    var body: some View {
        Text("Send/Receive Data")
            .p2pTitleStyle()
        HStack {
            Text("Counter: \(counter.count)").font(.largeTitle)
            Spacer()
            Button("+ 1") {
                counter.increment()
            }.p2pButtonStyle().font(.largeTitle)
        }
    }
}

#Preview {
    CounterView()
}
