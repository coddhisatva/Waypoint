//
//  MapView.swift
//  Waypoint
//
//  Created by Conor Egan on 8/16/25.
//

import SwiftUI
import GoogleMaps

struct MapView: View {
    @ObservedObject var locationManager: LocationManager
    @StateObject private var placesService = PlacesService()
    
    var body: some View {
        ZStack(alignment: .top) {
            // Google Maps
            GoogleMapView(locationManager: locationManager)
            
            // Transparent overlay to catch taps when search bar is focused
            if locationManager.isSearchBarFocused {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        print("🗺️ Overlay tapped! isSearchBarFocused: \(locationManager.isSearchBarFocused)")
                        print("🔍 Unfocusing search bar...")
                        locationManager.isSearchBarFocused = false
                        print("🔍 After unfocus: \(locationManager.isSearchBarFocused)")
                    }
            }
            
            // Search bar overlay - fixed position at top
            VStack(spacing: 0) {
                SearchBar(placesService: placesService, locationManager: locationManager)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .top)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct GoogleMapView: UIViewRepresentable {
    @ObservedObject var locationManager: LocationManager
    @State private var mapView: GMSMapView?
    @State private var hasSetInitialCamera = false
    
    func makeUIView(context: Context) -> GMSMapView {
        // Only create map once, don't reset camera on subsequent calls
        if let existingMapView = mapView {
            return existingMapView
        }
        
        let camera = GMSCameraPosition.camera(
            withLatitude: locationManager.currentLocation?.coordinates.latitude ?? 40.7829,
            longitude: locationManager.currentLocation?.coordinates.longitude ?? -73.9654,
            zoom: 15.0
        )
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        self.mapView = mapView
        
        // If we already have a location, mark camera as set
        if locationManager.currentLocation != nil {
            hasSetInitialCamera = true
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: GMSMapView, context: Context) {
        // Update camera to current location when it first becomes available
        if let current = locationManager.currentLocation, !hasSetInitialCamera {
            let camera = GMSCameraPosition.camera(
                withLatitude: current.coordinates.latitude,
                longitude: current.coordinates.longitude,
                zoom: 15.0
            )
            mapView.camera = camera
            hasSetInitialCamera = true
        }
        
        // Current location marker
        if let current = locationManager.currentLocation {
            let marker = GMSMarker()
            marker.position = current.coordinates
            marker.title = "Current Location"
            marker.icon = GMSMarker.markerImage(with: .blue)
            marker.map = mapView
        }
        
        // Destination marker
        if let destination = locationManager.destination {
            let marker = GMSMarker()
            marker.position = destination.coordinates
            marker.title = destination.displayName
            marker.snippet = destination.address
            marker.map = mapView
        }
    }
}
