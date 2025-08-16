//
//  WaypointApp.swift
//  Waypoint
//
//  Created by Conor Egan on 8/16/25.
//

import SwiftUI
import GoogleMaps

@main
struct WaypointApp: App {
    
    init() {
        // Read API key from Config.plist for security
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let apiKey = plist["GMSApiKey"] as? String {
            GMSServices.provideAPIKey(apiKey)
        } else {
            print("Error: Could not load Google Maps API key from Config.plist")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
