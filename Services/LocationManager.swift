//
//  LocationManager.swift
//  Waypoint
//
//  Created by Conor Egan on 8/16/25.
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let hapticService = HapticService()
    
    // MARK: - State
    
    @Published var currentLocation: CurrentLocation?
    @Published var destination: Destination?
    @Published var searchText: String = ""
    @Published var isSearchBarFocused: Bool = false
    @Published var recentDestinations: [Destination] = []
    @Published var bearingToDestination: Double = 0
    @Published var distanceToDestination: Double = 0
    @Published var alignmentError: Double = 0  // Signed difference: + = right of target, - = left of target
    private var lastGeocodeTime: Date = Date.distantPast  // Track last geocoding time
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Starts GPS and compass updates
    private func startLocationUpdates() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    /// Sets navigation destination and resets haptic state
    func setDestination(_ destination: Destination) {
        self.destination = destination
        addToHistory(destination)
        calculateBearingAndDistance()
        // Reset haptic state when setting new destination
        hapticService.resetAllState()
    }
    
    /// Adds a destination to recent history
    private func addToHistory(_ destination: Destination) {
        // Remove if already exists (to move to front)
        recentDestinations.removeAll { $0.address == destination.address }
        
        // Add to front
        recentDestinations.insert(destination, at: 0)
        
        // Keep only last 5
        if recentDestinations.count > 5 {
            recentDestinations = Array(recentDestinations.prefix(5))
        }
    }
    
    
    /// Calculates bearing and distance to destination
    private func calculateBearingAndDistance() {
        guard let current = currentLocation, let dest = destination else { return }
        
        let currentCLLocation = CLLocation(latitude: current.coordinates.latitude, longitude: current.coordinates.longitude)
        let destCLLocation = CLLocation(latitude: dest.coordinates.latitude, longitude: dest.coordinates.longitude)
        
        // Calculate distance
        distanceToDestination = currentCLLocation.distance(from: destCLLocation) / 1609.34 // Convert to miles
        
        // Calculate bearing
        bearingToDestination = calculateBearing(from: current.coordinates, to: dest.coordinates)
        
        // Update haptic feedback based on alignment
        updateHapticFeedback()
    }
    
    /// Updates haptic feedback based on compass alignment
    private func updateHapticFeedback() {
        guard let current = currentLocation, destination != nil else { return }
        
        // Calculate alignment error (signed and absolute)
        let currentHeading = current.heading
        alignmentError = calculateSignedAlignmentError(currentHeading: currentHeading, targetBearing: bearingToDestination)
        let degreesOffTarget = abs(alignmentError)
        
        // Update haptic service with alignment info
        hapticService.updateAlignmentFeedback(degreesOffTarget: degreesOffTarget)
    }
    
    /// Calculates signed alignment error (+ = right, - = left)
    private func calculateSignedAlignmentError(currentHeading: Double, targetBearing: Double) -> Double {
        // Calculate signed difference: positive = right of target, negative = left of target
        var difference = currentHeading - targetBearing
        
        // Normalize to -180 to +180 range
        while difference > 180 {
            difference -= 360
        }
        while difference < -180 {
            difference += 360
        }
        
        return difference  // Return signed value
    }
    
    /// Calculates bearing from one coordinate to another
    private func calculateBearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let deltaLon = (to.longitude - from.longitude) * .pi / 180
        
        let x = sin(deltaLon) * cos(lat2)
        let y = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        
        let bearing = atan2(x, y) * 180 / .pi
        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }
    
    /// Converts GPS coordinates to human-readable address
    private func reverseGeocode(location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let placemark = placemarks?.first else { return }
            
            DispatchQueue.main.async {
                let city = placemark.locality ?? ""
                let state = placemark.administrativeArea ?? ""
                let address = "\(city), \(state)"
                
                self?.currentLocation = CurrentLocation(
                    coordinates: location.coordinate,
                    heading: self?.currentLocation?.heading ?? 0,
                    address: address,
                    elevation: location.altitude * 3.28084 // Convert to feet
                )
            }
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    /// Called when GPS location updates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let newLocation = CurrentLocation(
            coordinates: location.coordinate,
            heading: currentLocation?.heading ?? 0,
            address: currentLocation?.address ?? "",
            elevation: location.altitude * 3.28084
        )
        
        currentLocation = newLocation
        
        // Only geocode every 15 seconds to avoid rate limiting
        let timeSinceLastGeocode = Date().timeIntervalSince(lastGeocodeTime)
        if timeSinceLastGeocode >= 15.0 {
            reverseGeocode(location: location)
            lastGeocodeTime = Date()
        }
        
        calculateBearingAndDistance()
    }
    
    /// Called when compass heading updates
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard let current = currentLocation else { return }
        
        currentLocation = CurrentLocation(
            coordinates: current.coordinates,
            heading: newHeading.trueHeading,
            address: current.address,
            elevation: current.elevation
        )
        
        calculateBearingAndDistance()
    }
    
    /// Called when location services encounter an error
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error)")
    }
    
    /// Called when location permission status changes
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            print("Location access denied")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
}
