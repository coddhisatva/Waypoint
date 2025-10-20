//
//  PlacesService.swift
//  Waypoint
//
//  Created by Conor Egan on 8/16/25.
//

import Foundation
import GooglePlaces
import CoreLocation

class PlacesService: ObservableObject {
    private let placesClient = GMSPlacesClient.shared()
    
    @Published var searchResults: [GMSAutocompletePrediction] = []
    
    func searchPlaces(query: String) {
        let filter = GMSAutocompleteFilter()
        
        placesClient.findAutocompletePredictions(fromQuery: query, filter: filter, sessionToken: nil) { [weak self] results, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Places search error: \(error)")
                    return
                }
                self?.searchResults = results ?? []
            }
        }
    }
    
    func getPlaceDetails(placeID: String, completion: @escaping (Destination?) -> Void) {
        let fields: GMSPlaceField = [.name, .coordinate, .formattedAddress]
        
        placesClient.fetchPlace(fromPlaceID: placeID, placeFields: fields, sessionToken: nil) { place, error in
            guard let place = place, error == nil else {
                print("Place details error: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            let destination = Destination(
                address: place.formattedAddress ?? place.name ?? "",
                coordinates: place.coordinate
            )
            
            completion(destination)
        }
    }
}
