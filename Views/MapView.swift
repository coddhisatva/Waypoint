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
                        //print("🗺️ Overlay tapped! isSearchBarFocused: \(locationManager.isSearchBarFocused)")
                        //print("🔍 Unfocusing search bar...")
                        locationManager.isSearchBarFocused = false
                        //print("🔍 After unfocus: \(locationManager.isSearchBarFocused)")
                    }
            }
            
            // Search bar overlay
            VStack {
                SearchBar(placesService: placesService, locationManager: locationManager)
                    .padding()
                Spacer()
            }
        }
    }
}

struct GoogleMapView: UIViewRepresentable {
    @ObservedObject var locationManager: LocationManager
    @State private var mapView: GMSMapView?
    
    private let MAP_ZOOM: Float = 15.0
    
    func makeUIView(context: Context) -> GMSMapView {
        // Restore saved camera position if available, otherwise use current location or default
        let camera: GMSCameraPosition
        if let mapCamera = locationManager.mapCamera {
            camera = mapCamera
        } else if let current = locationManager.currentLocation {
            camera = GMSCameraPosition.camera(
                withLatitude: current.coordinates.latitude,
                longitude: current.coordinates.longitude,
                zoom: MAP_ZOOM
            )
        } else {
            camera = GMSCameraPosition.camera(
                withLatitude: 40.7829,
                longitude: -73.9654,
                zoom: MAP_ZOOM
            )
        }
        
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        //ik i added this for some reason back then but seems to do nothing
        //self.mapView = mapView
        
        // Set up camera change delegate to save position
        mapView.delegate = context.coordinator
        context.coordinator.setMapView(mapView)
        
        return mapView
    }
    
    func updateUIView(_ mapView: GMSMapView, context: Context) {
        // Update camera to current location when it first becomes available (only if no saved camera)
        if let current = locationManager.currentLocation, locationManager.mapCamera == nil {
            let camera = GMSCameraPosition.camera(
                withLatitude: current.coordinates.latitude,
                longitude: current.coordinates.longitude,
                zoom: MAP_ZOOM
            )
            mapView.camera = camera
        }
        
        // Current location marker - update existing or create new
        if let current = locationManager.currentLocation {
            // Only update if location actually changed
            if context.coordinator.lastLocation != current {
                // Location changed, update marker
                if let marker = context.coordinator.currentLocationMarker {
                    marker.position = current.coordinates
                } else {
                    // Create new marker
                    let marker = GMSMarker()
                    marker.position = current.coordinates
                    marker.title = "Current Location"
                    marker.icon = GMSMarker.markerImage(with: .blue)
                    marker.map = mapView
                    context.coordinator.currentLocationMarker = marker
                }
                context.coordinator.lastLocation = current
            }
        } else {
            // Remove marker if no location
            context.coordinator.currentLocationMarker?.map = nil
            context.coordinator.currentLocationMarker = nil
            context.coordinator.lastLocation = nil
        }
        
        // Destination marker - update existing or create new
        if let destination = locationManager.destination {
            // Only update if destination actually changed
            if context.coordinator.lastDestination != destination {
                // Destination changed, update marker
                if let marker = context.coordinator.destinationMarker {
                    marker.position = destination.coordinates
                    marker.title = destination.displayName
                    marker.snippet = destination.address
                } else {
                    // Create new marker
                    let marker = GMSMarker()
                    marker.position = destination.coordinates
                    marker.title = destination.displayName
                    marker.snippet = destination.address
                    marker.map = mapView
                    context.coordinator.destinationMarker = marker
                }
                context.coordinator.lastDestination = destination
            }
        } else {
            // Remove marker if no destination
            context.coordinator.destinationMarker?.map = nil
            context.coordinator.destinationMarker = nil
            context.coordinator.lastDestination = nil
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(locationManager: locationManager)
    }
    
    class Coordinator: NSObject, GMSMapViewDelegate {
        var locationManager: LocationManager
        weak var mapView: GMSMapView?
        var currentLocationMarker: GMSMarker?
        var lastLocation: CurrentLocation?
        var destinationMarker: GMSMarker?
        var lastDestination: Destination?
        
        init(locationManager: LocationManager) {
            self.locationManager = locationManager
        }
        
        func setMapView(_ mapView: GMSMapView) {
            self.mapView = mapView
        }
        
        func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
            // Save camera position whenever it changes
            locationManager.mapCamera = position
        }
    }
}
