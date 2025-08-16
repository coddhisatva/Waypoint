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
    
    @Published var currentLocation: CurrentLocation?
    @Published var destination: Destination?
    @Published var bearingToDestination: Double = 0
    @Published var distanceToDestination: Double = 0
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func startLocationUpdates() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    func setDestination(_ destination: Destination) {
        self.destination = destination
        calculateBearingAndDistance()
    }
    
    private func calculateBearingAndDistance() {
        guard let current = currentLocation, let dest = destination else { return }
        
        let currentCLLocation = CLLocation(latitude: current.coordinates.latitude, longitude: current.coordinates.longitude)
        let destCLLocation = CLLocation(latitude: dest.coordinates.latitude, longitude: dest.coordinates.longitude)
        
        // Calculate distance
        distanceToDestination = currentCLLocation.distance(from: destCLLocation) / 1609.34 // Convert to miles
        
        // Calculate bearing
        bearingToDestination = calculateBearing(from: current.coordinates, to: dest.coordinates)
    }
    
    private func calculateBearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let deltaLon = (to.longitude - from.longitude) * .pi / 180
        
        let x = sin(deltaLon) * cos(lat2)
        let y = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        
        let bearing = atan2(x, y) * 180 / .pi
        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }
    
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
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let newLocation = CurrentLocation(
            coordinates: location.coordinate,
            heading: currentLocation?.heading ?? 0,
            address: currentLocation?.address ?? "",
            elevation: location.altitude * 3.28084
        )
        
        currentLocation = newLocation
        reverseGeocode(location: location)
        calculateBearingAndDistance()
    }
    
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
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error)")
    }
    
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
