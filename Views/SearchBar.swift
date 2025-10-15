//
//  SearchBar.swift
//  Waypoint
//
//  Created by Conor Egan on 8/16/25.
//

import SwiftUI
import GooglePlaces

struct SearchBar: View {
    @ObservedObject var placesService: PlacesService
    @ObservedObject var locationManager: LocationManager
    @State private var isSearching = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack {
            // Search field
            HStack {
                TextField("Search for a place", text: $locationManager.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isTextFieldFocused)
                    .onChange(of: locationManager.searchText) { _, newValue in
                        isSearching = !newValue.isEmpty
                        if !newValue.isEmpty {
                            placesService.searchPlaces(query: newValue)
                        }
                    }
                    .onChange(of: isTextFieldFocused) { _, focused in
                        // Only sync when TextField gains focus (false → true)
                        print("📝 TextField focus changed: \(focused), manager focus: \(locationManager.isSearchBarFocused)")
                        if focused == true && locationManager.isSearchBarFocused == false {
                            print("📝 Syncing focus to manager...")
                            locationManager.isSearchBarFocused = true
                        }
                    }
                    .onChange(of: locationManager.isSearchBarFocused) { _, focused in
                        // Only unfocus if we're currently focused and the manager says to unfocus
                        print("🔄 Manager focus changed: \(focused), TextField focused: \(isTextFieldFocused)")
                        if focused == false && isTextFieldFocused == true {
                            print("🔄 Unfocusing TextField...")
                            isTextFieldFocused = false
                        }
                    }
                    .onAppear {
                        // Show selected destination in search bar when view appears
                        if let destination = locationManager.destination {
                            locationManager.searchText = destination.displayName
                        }
                    }
                
                if !locationManager.searchText.isEmpty {
                    Button(action: {
                        locationManager.searchText = ""
                        isSearching = false
                        placesService.searchResults = []
                        // Also clear the selected destination
                        locationManager.destination = nil
                    }) {
                        Text("✕")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(.white)
                            .frame(width: 26, height: 26)
                            .background(Color.gray)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            }
            
            // Results list
            if isTextFieldFocused {
                VStack(spacing: 0) {
                    if isSearching && !placesService.searchResults.isEmpty {
                        // Show search results when typing
                        ForEach(placesService.searchResults.prefix(5), id: \.placeID) { prediction in
                            VStack(alignment: .leading) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(prediction.attributedPrimaryText.string)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        
                                        if let secondaryText = prediction.attributedSecondaryText?.string {
                                            Text(secondaryText)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            }
                            .background(Color(.systemBackground))
                            .onTapGesture {
                                selectPlace(prediction)
                            }
                            
                            if prediction.placeID != placesService.searchResults.prefix(5).last?.placeID {
                                Divider()
                            }
                        }
                    } else if !isSearching {
                        // Show history when focused but not searching (no text)
                        if !locationManager.recentDestinations.isEmpty {
                            ForEach(Array(locationManager.recentDestinations.enumerated()), id: \.element.address) { index, destination in
                                VStack(alignment: .leading) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(destination.displayName)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                            
                                            Text(destination.address)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                }
                                .background(Color(.systemBackground))
                                .onTapGesture {
                                    selectHistoryDestination(destination)
                                }
                                
                                if index < locationManager.recentDestinations.count - 1 {
                                    Divider()
                                }
                            }
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(radius: 4)
            }
            
        }
    }
    
    private func selectPlace(_ prediction: GMSAutocompletePrediction) {
        placesService.getPlaceDetails(placeID: prediction.placeID) { destination in
            if let destination = destination {
                DispatchQueue.main.async {
                    locationManager.setDestination(destination)
                    // Keep the selected place name in search bar instead of clearing
                    locationManager.searchText = destination.displayName
                    isSearching = false
                    placesService.searchResults = []
                }
            }
        }
    }
    
    private func selectHistoryDestination(_ destination: Destination) {
        locationManager.setDestination(destination)
        locationManager.searchText = destination.displayName
        isSearching = false
        placesService.searchResults = []
    }
}
