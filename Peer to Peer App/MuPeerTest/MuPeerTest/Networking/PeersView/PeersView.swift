//  Created by musesum on 12/4/22.

import SwiftUI

public struct PeersView: View {
    @ObservedObject public var peersVm: PeersVm
    var peersTitle: String { peersVm.peersTitle }
    var peersList: String { peersVm.peersList }
    public init(_ peersVm: PeersVm) { self.peersVm = peersVm }
    public var body: some View {
        VStack(alignment: .leading) {
            Text("Current Device").font(.headline)
            HStack {
                Text(peersTitle)
            }
            Spacer().frame(height: 16)
            Text("Detected Peers").font(.headline)
            Text(peersList)
        }
        .padding()
    }
}
