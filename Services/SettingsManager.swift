//
//  SettingsManager.swift
//  Waypoint
//
//  Created by Conor Egan on 8/16/25.
//

import Foundation

class SettingsManager: ObservableObject {
    @Published var hapticEnabled: Bool {
        didSet {
            UserDefaults.standard.set(hapticEnabled, forKey: "hapticEnabled")
            hapticService.isEnabled = hapticEnabled
        }
    }
    
    @Published var devTestingMode: Bool {
        didSet {
            UserDefaults.standard.set(devTestingMode, forKey: "devTestingMode")
        }
    }
    
    private let hapticService: HapticService
    
    init(hapticService: HapticService) {
        self.hapticService = hapticService
        
        // Load all settings from UserDefaults with defaults
        self.hapticEnabled = UserDefaults.standard.bool(forKey: "hapticEnabled")
        if !UserDefaults.standard.bool(forKey: "hapticEnabledSet") {
            self.hapticEnabled = true  // Default ON
            UserDefaults.standard.set(true, forKey: "hapticEnabled")
            UserDefaults.standard.set(true, forKey: "hapticEnabledSet")
        }
        
        self.devTestingMode = UserDefaults.standard.bool(forKey: "devTestingMode")
        if !UserDefaults.standard.bool(forKey: "devTestingModeSet") {
            self.devTestingMode = true  // Default ON
            UserDefaults.standard.set(true, forKey: "devTestingMode")
            UserDefaults.standard.set(true, forKey: "devTestingModeSet")
        }
        
        // Set initial haptic state
        hapticService.isEnabled = hapticEnabled
    }
}
