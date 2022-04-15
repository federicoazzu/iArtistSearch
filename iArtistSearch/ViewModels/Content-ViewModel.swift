//
//  Content-ViewModel.swift
//  iArtistSearch
//
//  Created by Federico on 11/04/2022.
//

import Foundation
import SwiftUI

enum LoadingState {
    case finished, loading
}

extension ContentView {
    final class ViewModel: ObservableObject {
        @Published var searchText: String = "linken park"
        @Published var apiState: LoadingState = .finished
        @Published var searchResults = [Search]()
        @Published var cachedResults = [Search]()
        
        @Published var displayingError = false
        @Published var errorMessage: String = ""
        @Published var sortResults = "aA"
        private let animationDelay = 0.5
        private let sf = SearchFormatter()
        
        init() {
            fetchSearchResults()
        }
        
        func hideKeyboard() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        
        // Sorts results alphabetically
        func sortResultsAlphabetically() {
            withAnimation {
                self.cacheResults()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + self.animationDelay) {
                    withAnimation {
                        if self.sortResults == "aA" {
                            self.sortResults = "Aa"
                            self.searchResults = self.cachedResults.sorted { $0.trackName.lowercased() < $1.trackName.lowercased() }
                        } else if self.sortResults == "Aa" {
                            self.sortResults = "aA"
                            self.searchResults = self.cachedResults.sorted { $0.trackName.lowercased() > $1.trackName.lowercased() }
                        }
                    }
                }
            }
        }
        
        
        func fetchSearchResults(limit: Int = 25) {
            // Make sure the user isn't searching nothing
            guard sf.isValidSearch(text: self.searchText) else {
                self.displayingError = true
                self.errorMessage = "Please insert a song / artist name."
                return }
            
            // Cache results
            withAnimation {
                self.cacheResults()
            }
            // Formats the string the user entered
            let search = sf.formatSearchString(text: self.searchText)
            
            // Prepares the URL for the request
            let url = "https://itunes.apple.com/search?term=\(search)&entity=musicTrack&country=dk&limit=\(limit)"
            
            self.apiState = .loading
            // Attempts to create an API request, otherwise returns a failure.
            Bundle.main.fetchData(url: url, model: ItunesResult.self) { data in
                // Add a delay to create a smooth animation
                DispatchQueue.main.asyncAfter(deadline: .now() + self.animationDelay) {
                    withAnimation {
                        self.searchResults = data.results
                        self.apiState = .finished
                    }
                    
                    if self.searchResults.isEmpty {
                        self.errorMessage = "There were no results..."
                        self.displayingError = true
                    }
                }
            } failure: { error in
                DispatchQueue.main.async {
                    self.handleError(error: error)
                }
            }
        }
        
        private func cacheResults() {
            self.cachedResults = self.searchResults
            self.searchResults = []
        }
        
        private func handleError(error: Error) {
            self.errorMessage = error.localizedDescription
            self.displayingError = true
            self.apiState = .finished
        }
    }
}
