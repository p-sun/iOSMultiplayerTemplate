//
//  DebugDataView.swift
//  P2PKitExample
//
//  Created by Paige Sun on 4/29/24.
//

import SwiftUI

struct DebugDataView: View {
    var body: some View {
        Button("Send Test Event") {
            let data = try! JSONEncoder().encode(["TEST EVENT": "from button!"])
            P2PNetwork.send(data: data)
        }
    }
}
