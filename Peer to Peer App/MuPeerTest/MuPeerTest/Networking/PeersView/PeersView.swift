//  Created by musesum on 12/4/22.

import SwiftUI

public struct PeersView: View {
    @ObservedObject public var peersVm: PeersVm
    var peersTitle: String { peersVm.peersTitle }
    var peersList: String { peersVm.peersList }
    public init(_ peersVm: PeersVm) {self.peersVm = peersVm}
    public var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "globe")
                    .imageScale(.medium)
                    .foregroundColor(.white)
                Text(peersTitle)
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 1.0)
            }
            Text(peersList)
                .foregroundColor(.white)
                .shadow(color: .black, radius: 1.0)
        }
        .padding()
    }
}
