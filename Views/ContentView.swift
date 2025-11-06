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
            

            // Keep both views in memory, just hide/show them
            MapView(locationManager: locationManager)
                .opacity(showingMapView ? 1 : 0)
                .allowsHitTesting(showingMapView)
            
            CompassView(locationManager: locationManager)
                .opacity(showingMapView ? 0 : 1)
                .allowsHitTesting(!showingMapView)
            
            // Toggle button (bottom left)
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        showingMapView.toggle()
                        // Unfocus search bar when switching to map view
                        if showingMapView {
                            locationManager.isSearchBarFocused = false
                        }
                    }) {
                        Image(systemName: showingMapView ? "safari.fill" : "map.circle.fill")
                            .font(.system(size: 32)) // Increased from .title
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(showingMapView ? Color.black.opacity(0.6) : Color.white.opacity(0.3))
                                    .frame(width: 60, height: 60) // Explicit larger background
                            )
                    }
                    .frame(width: 60, height: 60) // Larger touch target
                    .padding(.leading, 20)
                    .padding(.bottom, 40)
                    Spacer()
                }
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    ContentView()
}
