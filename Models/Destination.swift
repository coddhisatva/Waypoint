//
//  Destination.swift
//  Waypoint
//
//  Created by Conor Egan on 8/16/25.
//

import Foundation
import CoreLocation

struct Destination: Codable {
    let address: String // "Central Park, New York, NY"
    let displayName: String // "Central Park"
    let coordinates: CLLocationCoordinate2D
    
    init(address: String, coordinates: CLLocationCoordinate2D) {
        self.address = address
        self.coordinates = coordinates
        // Extract display name from full address (first part before comma)
        self.displayName = address.components(separatedBy: ",").first ?? address
    }
    
    // Custom Codable implementation for CLLocationCoordinate2D
    private enum CodingKeys: String, CodingKey {
        case address, displayName, latitude, longitude
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        address = try container.decode(String.self, forKey: .address)
        displayName = try container.decode(String.self, forKey: .displayName)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(address, forKey: .address)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(coordinates.latitude, forKey: .latitude)
        try container.encode(coordinates.longitude, forKey: .longitude)
    }
}
