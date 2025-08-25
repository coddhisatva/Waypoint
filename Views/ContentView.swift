//
//  ContentView.swift
//  Waypoint
//
//  Created by Conor Egan on 8/16/25.
//

import SwiftUI

enum ViewType: CaseIterable {
    case compass, map, settings
    
    var next: ViewType {
        let allCases = ViewType.allCases
        let currentIndex = allCases.firstIndex(of: self)!
        let nextIndex = (currentIndex + 1) % allCases.count
        return allCases[nextIndex]
    }
    
    var previous: ViewType {
        let allCases = ViewType.allCases
        let currentIndex = allCases.firstIndex(of: self)!
        let previousIndex = (currentIndex - 1 + allCases.count) % allCases.count
        return allCases[previousIndex]
    }
}

struct ContentView: View {
    @StateObject private var hapticService = HapticService()
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var locationManager: LocationManager
    @State private var currentView: ViewType = .compass
    
    init() {
        let haptic = HapticService()
        let settings = SettingsManager()
        self._hapticService = StateObject(wrappedValue: haptic)
        self._settingsManager = StateObject(wrappedValue: settings)
        self._locationManager = StateObject(wrappedValue: LocationManager(hapticService: haptic))
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Main content based on current view
            switch currentView {
            case .compass:
                CompassView(locationManager: locationManager, hapticService: hapticService, devTestingMode: settingsManager.devTestingMode)
            case .map:
                MapView(locationManager: locationManager)
            case .settings:
                SettingsView(hapticService: hapticService, devTestingMode: $settingsManager.devTestingMode)
            }
            
            // Navigation buttons overlay
            VStack {
                Spacer()
                HStack {
                    // Left side: Map/Compass toggle button
                    Button(action: {
                        currentView = currentView == .compass ? .map : .compass
                    }) {
                        Image(systemName: currentView == .map ? "safari.fill" : "map.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(currentView == .map ? Color.black.opacity(0.6) : Color.white.opacity(0.3))
                                    .frame(width: 60, height: 60)
                            )
                    }
                    .frame(width: 60, height: 60)
                    .padding(.leading, 20)
                    .padding(.bottom, 40)
                    
                    Spacer()
                    
                    // Right side: Settings button
                    Button(action: {
                        currentView = .settings
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(width: 60, height: 60)
                            )
                    }
                    .frame(width: 60, height: 60)
                    .padding(.trailing, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    let threshold: CGFloat = 50
                    if value.translation.x > threshold {
                        // Swipe right: go to previous view
                        currentView = currentView.previous
                    } else if value.translation.x < -threshold {
                        // Swipe left: go to next view
                        currentView = currentView.next
                    }
                }
        )
    }
}

#Preview {
    ContentView()
}
