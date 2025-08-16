//
//  Destination.swift
//  Waypoint
//
//  Created by Conor Egan on 8/16/25.
//

import Foundation
import CoreLocation

struct Destination {
    let address: String // "Central Park, New York, NY"
    let displayName: String // "Central Park"
    let coordinates: CLLocationCoordinate2D
    
    init(address: String, coordinates: CLLocationCoordinate2D) {
        self.address = address
        self.coordinates = coordinates
        // Extract display name from full address (first part before comma)
        self.displayName = address.components(separatedBy: ",").first ?? address
    }
}
