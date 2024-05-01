//
//  DebugDataView.swift
//  P2PKitExample
//
//  Created by Paige Sun on 4/29/24.
//

import SwiftUI

class DebugDataViewModel: ObservableObject {
    @Published var recentJsons = [String]()
    
    init() {
        P2PNetwork.addDelegate(self)
    }
}

extension DebugDataViewModel: P2PNetworkSessionDelegate {
    func p2pNetworkSession(_ session: P2PNetworkSession, didUpdate player: Player) { }
    
    func p2pNetworkSession(_ session: P2PNetworkSession, didReceive data: Data, dataAsJson json: [String : Any]?, from player: Player) -> Bool {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let json = json {
                self.recentJsons = ["\(json)"] + self.recentJsons
            }
        }
        return false
    }
}

struct DebugDataView: View {
    @StateObject var model = DebugDataViewModel()
    
    var body: some View {
        Text("Last received data")
            .p2pTitleStyle()
        ScrollView {
            HStack {
                VStack(alignment: .leading) {
                    ForEach(model.recentJsons.indices, id: \.self) { index in
                        Text(model.recentJsons[index])
                    }
                }
                Spacer()
            }
        }
        .frame(height: 160)
        .background(Color.mint.opacity(0.3))
    }
}

#Preview {
    DebugDataView()
}
