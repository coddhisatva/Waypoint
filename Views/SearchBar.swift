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
    @State private var searchText = ""
    @State private var isSearching = false
    
    var body: some View {
        VStack {
            // Search field
            HStack {
                TextField("Search for a place", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: searchText) { newValue in
                        isSearching = !newValue.isEmpty
                        if !newValue.isEmpty {
                            placesService.searchPlaces(query: newValue)
                        }
                    }
                    .onAppear {
                        // Show selected destination in search bar when view appears
                        if let destination = locationManager.destination {
                            searchText = destination.displayName
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        isSearching = false
                        placesService.searchResults = []
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
            if isSearching && !placesService.searchResults.isEmpty {
                VStack(spacing: 0) {
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
                    searchText = destination.displayName
                    isSearching = false
                    placesService.searchResults = []
                }
            }
        }
    }
}
