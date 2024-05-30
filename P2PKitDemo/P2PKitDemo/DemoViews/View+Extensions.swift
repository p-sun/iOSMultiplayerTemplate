//
//  View+Extensions.swift
//  P2PKitDemo
//
//  Created by Paige Sun on 5/14/24.
//

import SwiftUI

extension View {
    public func p2pButtonStyle() -> some View {
        self.buttonStyle(.borderedProminent).tint(.mint).foregroundColor(.black)
    }
    
    public func p2pSecondaryButtonStyle() -> some View {
        self.buttonStyle(.bordered)
            .tint(.mint).foregroundColor(.black)
    }
}

extension Text {
    func p2pTitleStyle() -> some View {
        return self.font(.title)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(EdgeInsets(top: 14, leading: 0, bottom: 0, trailing: 0))
    }
}
