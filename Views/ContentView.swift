//
//  ContentView.swift
//  Waypoint
//
//  Created by Conor Egan on 8/16/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text("Waypoint App")
                .foregroundColor(.white)
        }
    }
}

#Preview {
    ContentView()
}
