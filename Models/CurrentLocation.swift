//
//  CurrentLocation.swift
//  Waypoint
//
//  Created by Conor Egan on 8/16/25.
//

import Foundation
import CoreLocation

struct CurrentLocation: Equatable {
    let coordinates: CLLocationCoordinate2D
    let heading: Double // degrees from North (0-360)
    let address: String // "Newark, NJ"
    let elevation: Double // in feet
    
    init(coordinates: CLLocationCoordinate2D, heading: Double, address: String = "", elevation: Double = 0) {
        self.coordinates = coordinates
        self.heading = heading
        self.address = address
        self.elevation = elevation
    }
    
    static func == (lhs: CurrentLocation, rhs: CurrentLocation) -> Bool {
        return lhs.coordinates.latitude == rhs.coordinates.latitude &&
               lhs.coordinates.longitude == rhs.coordinates.longitude
    }
}
