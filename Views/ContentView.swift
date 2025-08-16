//
//  ContentView.swift
//  Waypoint
//
//  Created by Conor Egan on 8/16/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var showingMapView = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if showingMapView {
                MapView(locationManager: locationManager)
            } else {
                CompassView(locationManager: locationManager)
            }
            
            // Toggle button (bottom left)
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        showingMapView.toggle()
                    }) {
                        Image(systemName: showingMapView ? "location.north.circle.fill" : "map.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .padding()
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
