//
//  SettingsView.swift
//  Waypoint
//
//  Created by Conor Egan on 8/16/25.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @Binding var devTestingMode: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Settings header
                    Text("Settings")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 60)
                    
                    Spacer()
                    
                    // Settings options
                    VStack(spacing: 25) {
                        // Haptic feedback toggle
                        HStack {
                            Text("Haptic Feedback")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Toggle("", isOn: $settingsManager.hapticEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                        }
                        .padding(.horizontal, 30)
                        
                        // Dev testing mode toggle
                        HStack {
                            Text("Dev Testing Mode")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Toggle("", isOn: $devTestingMode)
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                        }
                        .padding(.horizontal, 30)
                    }
                    
                    Spacer()
                    
                    // Buy me a coffee button
                    Button(action: {
                        if let url = URL(string: "https://www.youtube.com/@YoungsterSkaymore") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text("Buy me a coffee")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.blue)
                            )
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    SettingsView(
        settingsManager: SettingsManager(hapticService: HapticService()),
        devTestingMode: .constant(true)
    )
}
