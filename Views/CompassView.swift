//
//  CompassView.swift
//  Waypoint
//
//  Created by Conor Egan on 8/16/25.
//

import SwiftUI
import CoreLocation

struct CompassView: View {
    @ObservedObject var locationManager: LocationManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Top section - Destination info (read-only)
            destinationSection
                .padding(.top, 60)
                .padding(.horizontal, 20)
            
            Spacer()
            
            // Compass
            ZStack {
                CompassRing(heading: locationManager.currentLocation?.heading ?? 0)
                CompassNeedle(heading: locationManager.currentLocation?.heading ?? 0)
                if locationManager.destination != nil {
                    DestinationPin(
                        bearing: locationManager.bearingToDestination,
                        currentHeading: locationManager.currentLocation?.heading ?? 0
                    )
                }
            }
            .frame(width: 300, height: 300)
            
            Spacer()
            
            // Bottom section - Current location info
            currentLocationSection
                .padding(.bottom, 100)
                .padding(.horizontal, 20)
        }
        .foregroundColor(.white)
    }
    
    private var destinationSection: some View {
        VStack(spacing: 8) {
            if let destination = locationManager.destination {
                Text(destination.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(formatCoordinates(destination.coordinates))
                    .font(.caption)
                    .opacity(0.8)
                
                Text(formatDistance(locationManager.distanceToDestination))
                    .font(.caption)
                    .opacity(0.8)
            } else {
                Text("No destination selected")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Set destination on maps screen")
                    .font(.caption)
                    .opacity(0.8)
            }
        }
    }
    
    private var currentLocationSection: some View {
        VStack(spacing: 8) {
            // Current heading
            Text("\(Int(locationManager.currentLocation?.heading ?? 0))° \(headingDirection)")
                .font(.system(size: 48, weight: .thin))
            
            if let current = locationManager.currentLocation {
                // Coordinates
                Text(formatCoordinates(current.coordinates))
                    .font(.system(size: 16, weight: .light))
                
                // Location name
                Text(current.address)
                    .font(.system(size: 16, weight: .light))
                
                // Elevation
                Text("\(Int(current.elevation)) ft Elevation")
                    .font(.system(size: 16, weight: .light))
                
                // Waypoint alignment testing (only show if destination exists)
                if locationManager.destination != nil {
                    Text(waypointAlignmentText)
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(.yellow) // Different color for testing visibility
                }
            }
        }
    }
    
    private func formatDistance(_ miles: Double) -> String {
        // Convert miles to meters for the threshold check
        let meters = miles * 1609.34
        
        if meters < 322 { // 0.2 miles = 322 meters
            // Show meters when under 0.2 miles
            return String(format: "%.0f m", meters)
        } else {
            // Show miles when 0.2 miles or more
            return String(format: "%.1f miles", miles)
        }
    }
    
    private func formatCoordinates(_ coordinates: CLLocationCoordinate2D) -> String {
        let latDegrees = abs(coordinates.latitude)
        let latMinutes = (latDegrees.truncatingRemainder(dividingBy: 1)) * 60
        let latSeconds = (latMinutes.truncatingRemainder(dividingBy: 1)) * 60
        
        let lonDegrees = abs(coordinates.longitude)
        let lonMinutes = (lonDegrees.truncatingRemainder(dividingBy: 1)) * 60
        let lonSeconds = (lonMinutes.truncatingRemainder(dividingBy: 1)) * 60
        
        let latDirection = coordinates.latitude >= 0 ? "N" : "S"
        let lonDirection = coordinates.longitude >= 0 ? "E" : "W"
        
        return String(format: "%.0f°%.0f'%.0f\" %@ %.0f°%.0f'%.0f\" %@",
                     latDegrees, latMinutes, latSeconds, latDirection,
                     lonDegrees, lonMinutes, lonSeconds, lonDirection)
    }
    
    private var headingDirection: String {
        let heading = locationManager.currentLocation?.heading ?? 0
        
        switch heading {
        case 337.5...360, 0..<22.5: return "N"
        case 22.5..<67.5: return "NE"
        case 67.5..<112.5: return "E"
        case 112.5..<157.5: return "SE"
        case 157.5..<202.5: return "S"
        case 202.5..<247.5: return "SW"
        case 247.5..<292.5: return "W"
        case 292.5..<337.5: return "NW"
        default: return "N"
        }
    }
    
    private var waypointAlignmentText: String {
        let alignmentError = locationManager.alignmentError
        let absDifference = abs(alignmentError)
        
        // If perfectly aligned, just show 0°
        if absDifference < 1 {
            return "0°"
        }
        
        // If exactly opposite (180°), no direction needed
        if absDifference >= 179.5 {
            return "180°"
        }
        
        let direction = alignmentError > 0 ? "R" : "L"
        return "\(Int(absDifference))° \(direction)"
    }
}
